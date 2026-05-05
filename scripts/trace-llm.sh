#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRACE_PATH="${REDWRIGHT_LLM_TRACE_PATH:-$ROOT_DIR/.log/llm.ndjson}"
MODE="conversation"
SOURCE_CHANNEL=""

usage() {
  cat <<'USAGE'
Usage: scripts/trace-llm.sh [--compact|--pretty] [--source SOURCE_CHANNEL] [--path FILE]

Tails RedWright LLM trace events from .log/llm.ndjson.

Options:
  --compact                Print one tab-separated line per event.
  --pretty                 Pretty-print full JSON events.
  --conversation           Pretty-print request prompts and responses. Default.
  --source SOURCE_CHANNEL  Filter by source_channel, for example project_setup or telegram.
  --path FILE              Read another NDJSON trace file.
  -h, --help               Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --compact)
      MODE="compact"
      shift
      ;;
    --pretty)
      MODE="pretty"
      shift
      ;;
    --conversation)
      MODE="conversation"
      shift
      ;;
    --source)
      SOURCE_CHANNEL="${2:-}"
      if [[ -z "$SOURCE_CHANNEL" ]]; then
        echo "missing value for --source" >&2
        exit 2
      fi
      shift 2
      ;;
    --path)
      TRACE_PATH="${2:-}"
      if [[ -z "$TRACE_PATH" ]]; then
        echo "missing value for --path" >&2
        exit 2
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to inspect LLM traces" >&2
  exit 1
fi

mkdir -p "$(dirname "$TRACE_PATH")"
touch "$TRACE_PATH"

if [[ "$MODE" == "pretty" ]]; then
  if [[ -n "$SOURCE_CHANNEL" ]]; then
    exec tail -n 20 -f "$TRACE_PATH" | jq --unbuffered --arg source "$SOURCE_CHANNEL" 'select(.source_channel == $source)'
  fi
  exec tail -n 20 -f "$TRACE_PATH" | jq --unbuffered .
fi

print_conversation_event() {
  local line="$1"
  local event
  local payload

  if [[ -n "$SOURCE_CHANNEL" ]]; then
    if ! jq -e --arg source "$SOURCE_CHANNEL" '.source_channel == $source' >/dev/null 2>&1 <<<"$line"; then
      return 0
    fi
  fi

  event="$(jq -r '.event // ""' <<<"$line")"
  [[ "$event" == "llm_request" || "$event" == "llm_response" ]] || return 0

  if [[ "$event" == "llm_request" ]]; then
    jq -r '
      "\n=== LLM REQUEST ===",
      "time: \(.timestamp)",
      "id: \(.llm_call_id)",
      "trace: \(.trace_id // "")",
      "source: \(.source_channel // "")",
      "action: \(.action // "")",
      "model: \(.model // "")",
      "prompt:"
    ' <<<"$line"
    payload="$(jq -r '.user_text // ""' <<<"$line")"
  else
    jq -r '
      "\n=== LLM RESPONSE ===",
      "time: \(.timestamp)",
      "id: \(.llm_call_id)",
      "status: \(.status // "")",
      "finish: \(.finish_reason // "")",
      "latency_ms: \(.latency_ms // "")",
      (if (.error // "") != "" then "error: \(.error)" else empty end),
      "response:"
    ' <<<"$line"
    payload="$(jq -r 'if (.parsed_message // "") != "" then .parsed_message else (.raw_output // .error // "") end' <<<"$line")"
  fi

  if jq -e . >/dev/null 2>&1 <<<"$payload"; then
    jq . <<<"$payload"
  else
    printf '%s\n' "$payload"
  fi
}

if [[ "$MODE" == "conversation" ]]; then
  tail -n 20 -f "$TRACE_PATH" | while IFS= read -r line; do
    print_conversation_event "$line"
  done
  exit 0
fi

if [[ -n "$SOURCE_CHANNEL" ]]; then
  exec tail -n 20 -f "$TRACE_PATH" | jq --unbuffered -r --arg source "$SOURCE_CHANNEL" '
    select(.source_channel == $source) |
    [
      .timestamp,
      .event,
      .source_channel,
      .action,
      .llm_call_id,
      (.status // ""),
      (.model // ""),
      (if (.parsed_message // "") != "" then .parsed_message else (.user_text // .raw_output // .error // "") end)
    ] | @tsv
  '
fi

exec tail -n 20 -f "$TRACE_PATH" | jq --unbuffered -r '
  [
    .timestamp,
    .event,
    .source_channel,
    .action,
    .llm_call_id,
    (.status // ""),
    (.model // ""),
    (if (.parsed_message // "") != "" then .parsed_message else (.user_text // .raw_output // .error // "") end)
  ] | @tsv
'
