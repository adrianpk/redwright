#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REFERENCE_DIR="$ROOT_DIR/_workspace/testing/reference/go-todo-agent"
PROJECT_DIR="$ROOT_DIR/_workspace/Projects/go-todo-agent"

print_repo_state() {
  local label="$1"
  local path="$2"

  echo
  echo "== $label =="
  echo "path: $path"

  if [[ ! -d "$path" ]]; then
    echo "missing directory"
    return 1
  fi

  if [[ ! -d "$path/.git" ]]; then
    echo "missing .git directory"
    return 1
  fi

  git -C "$path" log --oneline --decorate -1
  git -C "$path" status --short --branch
}

print_repo_state "reference" "$REFERENCE_DIR"
print_repo_state "active project" "$PROJECT_DIR"

echo
echo "== active project vs reference =="
if diff -qr -x .git "$REFERENCE_DIR" "$PROJECT_DIR"; then
  echo "no filesystem differences outside .git"
else
  echo
  echo "content diff:"
  diff -ruN -x .git "$REFERENCE_DIR" "$PROJECT_DIR" || true
fi

if [[ "${1:-}" == "--with-test" ]]; then
  echo
  echo "== active project test =="
  if (
    cd "$PROJECT_DIR"
    go test ./...
  ); then
    echo "go test ./...: pass"
  else
    echo "go test ./...: fail"
  fi
fi
