#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAILS_API_URL="${REDWRIGHT_RAILS_API_URL:-http://localhost:3000/api/v1}"
RAILS_BOOT_DELAY_SECONDS="${RAILS_BOOT_DELAY_SECONDS:-2}"

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
