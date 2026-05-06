#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAILS_API_URL="${REDWRIGHT_RAILS_API_URL:-http://localhost:3000/api/v1}"
RAILS_BOOT_DELAY_SECONDS="${RAILS_BOOT_DELAY_SECONDS:-2}"
WEB_PID_FILE="$ROOT_DIR/apps/web/tmp/pids/server.pid"

pids=()

stop_children() {
  trap - EXIT INT TERM

  for pid in "${pids[@]:-}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
    fi
  done

  wait || true
}

trap stop_children EXIT
trap 'exit 130' INT TERM

reset_rails_pid_file() {
  if [[ ! -f "$WEB_PID_FILE" ]]; then
    return
  fi

  local pid
  pid="$(tr -d '[:space:]' < "$WEB_PID_FILE")"

  if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
    echo "Stopping existing Rails server pid $pid from $WEB_PID_FILE"
    kill "$pid" 2>/dev/null || true

    for _ in {1..20}; do
      if ! kill -0 "$pid" 2>/dev/null; then
        break
      fi
      sleep 0.1
    done

    if kill -0 "$pid" 2>/dev/null; then
      echo "Force stopping existing Rails server pid $pid"
      kill -9 "$pid" 2>/dev/null || true
    fi
  fi

  rm -f "$WEB_PID_FILE"
}

reset_rails_pid_file

echo "Starting Rails web on http://localhost:3000"
(
  cd "$ROOT_DIR/apps/web"
  exec bin/dev
) &
pids+=("$!")

sleep "$RAILS_BOOT_DELAY_SECONDS"

echo "Starting Telegram daemon with REDWRIGHT_RAILS_API_URL=$RAILS_API_URL"
(
  cd "$ROOT_DIR"
  export REDWRIGHT_RAILS_API_URL="$RAILS_API_URL"
  exec bundle exec ruby bin/redwright daemon run --dev --ingress telegram
) &
pids+=("$!")

wait -n "${pids[@]}"
