#!/usr/bin/env bash
set -euo pipefail

# Print a compact guide for the repository-local RedWright ticket workflow.
#
# Usage:
#   scripts/agent/tickets/help.sh
#
# This is intentionally human-facing. It summarizes the commands that agents
# and humans can both use without remembering the full playbook.

cat <<'HELP'
RedWright Ticket Helpers

Tickets are Markdown files for RedWright development work.

Directory columns:
  ops/tickets/open/         captured, not necessarily refined
  ops/tickets/ready/        clear enough to execute
  ops/tickets/in_progress/  actively being worked
  ops/tickets/reviewing/    implementation/proposal ready for review
  ops/tickets/blocked/      waiting on dependency or decision
  ops/tickets/solved/       resolved positively, usually merged
  ops/tickets/closed/       closed without implemented resolution

Create a ticket:
  scripts/agent/tickets/new.sh "Support Markdown ticket body editing"

Create a ticket with tags:
  scripts/agent/tickets/new.sh "Support Markdown ticket body editing" \
    --tags "ticket-body, markdown, web"

List/search tickets:
  scripts/agent/tickets/search.sh
  scripts/agent/tickets/search.sh --status open
  scripts/agent/tickets/search.sh markdown
  scripts/agent/tickets/search.sh markdown --format paths
  scripts/agent/tickets/search.sh --tag web --format long

Validate ticket consistency:
  scripts/agent/tickets/check.sh

What check.sh validates:
  - ticket status matches its directory
  - filename starts with YYYYMMDDHHMMSS-
  - id matches the filename timestamp
  - required frontmatter fields exist
  - enum fields use known values
  - tags are lowercase kebab-case and max 5
  - solved/closed tickets have closed_at and resolution

Capture rule:
  Ticket creation should be low friction. Classification fields can stay
  unclassified and be handled later during triage.
HELP
