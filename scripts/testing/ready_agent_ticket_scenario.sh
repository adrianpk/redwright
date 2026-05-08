#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_DIR="$ROOT_DIR/_workspace/Projects/go-todo-agent"

cd "$ROOT_DIR/apps/web"
RESET_OUTPUT="$(bin/rails runner ../../scripts/testing/prepare_agent_ticket_scenario.rb)"

cd "$ROOT_DIR"
echo "$RESET_OUTPUT"
./scripts/testing/inspect_agent_ticket_scenario.sh

echo
echo "== manual command =="
echo "/ticket start RW-10"
echo
echo "Before running the Telegram command, open a fresh shell or run:"
echo "cd $PROJECT_DIR"
