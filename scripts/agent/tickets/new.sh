#!/usr/bin/env bash
set -euo pipefail

# Create a repository-local RedWright development ticket.
#
# Common usage:
#   scripts/agent/tickets/new.sh "Support Markdown ticket body editing"
#   scripts/agent/tickets/new.sh "Support Markdown ticket body editing" \
#     --tags "ticket-body, markdown, web" \
#     --description "Ticket bodies should support Markdown and render nicely."
#
# The script intentionally defaults classification fields to `unclassified`.
# Capture should be fast; classification can happen later through triage.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TITLE=""
DESCRIPTION=""
TAGS=""
KIND="unclassified"
SEVERITY="unclassified"
PRIORITY="unclassified"
SCOPE="unclassified"
SOURCE="chat"
OWNER=""

usage() {
  cat <<'USAGE'
Usage: scripts/agent/tickets/new.sh "Ticket title" [options]

Creates an open ticket under ops/tickets/open/ using the canonical ticket
frontmatter and filename/id format.

Options:
  --description TEXT  Raw context/problem description to place in the body.
  --tags LIST         Comma-separated tags, ideal 1-3 and max 5.
  --kind VALUE        unclassified|bug|task|cleanup|follow_up|research|decision
  --severity VALUE    unclassified|low|medium|high|critical
  --priority VALUE    unclassified|low|normal|high|urgent
  --scope VALUE       unclassified|ops|web|runtime|llm|project_setup|docs|infra
  --source VALUE      chat|manual_test|review|trace|user_report|implementation
  --owner VALUE       Optional owner.
  -h, --help          Show this help.

Examples:
  scripts/agent/tickets/new.sh "Add ticket comments"
  scripts/agent/tickets/new.sh "Add ticket comments" --tags "ticket-comments, web"
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --description)
      DESCRIPTION="${2:-}"
      [[ -n "$DESCRIPTION" ]] || { echo "missing value for --description" >&2; exit 2; }
      shift 2
      ;;
    --tags)
      TAGS="${2:-}"
      [[ -n "$TAGS" ]] || { echo "missing value for --tags" >&2; exit 2; }
      shift 2
      ;;
    --kind)
      KIND="${2:-}"
      [[ -n "$KIND" ]] || { echo "missing value for --kind" >&2; exit 2; }
      shift 2
      ;;
    --severity)
      SEVERITY="${2:-}"
      [[ -n "$SEVERITY" ]] || { echo "missing value for --severity" >&2; exit 2; }
      shift 2
      ;;
    --priority)
      PRIORITY="${2:-}"
      [[ -n "$PRIORITY" ]] || { echo "missing value for --priority" >&2; exit 2; }
      shift 2
      ;;
    --scope)
      SCOPE="${2:-}"
      [[ -n "$SCOPE" ]] || { echo "missing value for --scope" >&2; exit 2; }
      shift 2
      ;;
    --source)
      SOURCE="${2:-}"
      [[ -n "$SOURCE" ]] || { echo "missing value for --source" >&2; exit 2; }
      shift 2
      ;;
    --owner)
      OWNER="${2:-}"
      [[ -n "$OWNER" ]] || { echo "missing value for --owner" >&2; exit 2; }
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -z "$TITLE" ]]; then
        TITLE="$1"
      else
        echo "unexpected extra argument: $1" >&2
        usage >&2
        exit 2
      fi
      shift
      ;;
  esac
done

if [[ -z "$TITLE" ]]; then
  echo "ticket title is required" >&2
  usage >&2
  exit 2
fi

export TITLE DESCRIPTION TAGS KIND SEVERITY PRIORITY SCOPE SOURCE OWNER ROOT_DIR

ruby <<'RUBY'
require "fileutils"
require "time"

root = ENV.fetch("ROOT_DIR")
title = ENV.fetch("TITLE").strip
description = ENV.fetch("DESCRIPTION").strip
tags = ENV.fetch("TAGS").strip
kind = ENV.fetch("KIND").strip
severity = ENV.fetch("SEVERITY").strip
priority = ENV.fetch("PRIORITY").strip
scope = ENV.fetch("SCOPE").strip
source = ENV.fetch("SOURCE").strip
owner = ENV.fetch("OWNER").strip

allowed = {
  "kind" => %w[unclassified bug task cleanup follow_up research decision],
  "severity" => %w[unclassified low medium high critical],
  "priority" => %w[unclassified low normal high urgent],
  "scope" => %w[unclassified ops web runtime llm project_setup docs infra],
  "source" => %w[chat manual_test review trace user_report implementation]
}

allowed.each do |field, values|
  value = binding.local_variable_get(field.to_sym)
  abort "#{field} must be one of: #{values.join(', ')}" unless values.include?(value)
end

if tags.split(",").map(&:strip).reject(&:empty?).length > 5
  abort "tags must contain at most 5 comma-separated values"
end

timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
reported_at = Time.now.utc.iso8601
slug = title.downcase
  .gsub(/[^a-z0-9]+/, "-")
  .gsub(/^-|-$/, "")
  .then { |value| value.empty? ? "ticket" : value }

dir = File.join(root, "ops/tickets/open")
FileUtils.mkdir_p(dir)
path = File.join(dir, "#{timestamp}-#{slug}.md")

if File.exist?(path)
  abort "ticket already exists: #{path}"
end

body_description = description.empty? ? "Captured from chat. To be clarified during triage." : description

content = <<~MARKDOWN
  ---
  id: TKT-#{timestamp}
  title: #{title}
  status: open
  kind: #{kind}
  severity: #{severity}
  priority: #{priority}
  scope: #{scope}
  tags: #{tags}
  source: #{source}
  reported_at: #{reported_at}
  ready_at:
  started_at:
  reviewed_at:
  closed_at:
  resolution:
  owner: #{owner}
  branch:
  pr:
  commits: []
  ---

  ## Context
  #{body_description}

  ## Problem
  To be clarified during triage.

  ## Expected
  - To be clarified during triage.

  ## Actual
  - To be verified during triage and implementation.

  ## Fix Strategy
  - Pending triage.

  ## Validation
  - Pending triage.

  ## Outcome
  Pending implementation.
MARKDOWN

File.write(path, content)
puts path.sub("#{root}/", "")
RUBY
