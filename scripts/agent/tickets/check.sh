#!/usr/bin/env bash
set -euo pipefail

# Validate repository-local RedWright development tickets.
#
# Common usage:
#   scripts/agent/tickets/check.sh
#
# This checks the invariants documented in .agents/playbooks/ticket-workflow.md:
# - ticket status matches its directory column
# - ids match sortable filename timestamps
# - required frontmatter is present
# - enum fields use known values
# - tags are comma-separated and capped at five

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
export ROOT_DIR

ruby <<'RUBY'
root = ENV.fetch("ROOT_DIR")
ticket_glob = File.join(root, "ops/tickets/{open,ready,in_progress,reviewing,blocked,solved,closed}/*.md")

allowed = {
  "status" => %w[open ready in_progress reviewing blocked solved closed],
  "kind" => %w[unclassified bug task cleanup follow_up research decision],
  "severity" => %w[unclassified low medium high critical],
  "priority" => %w[unclassified low normal high urgent],
  "scope" => %w[unclassified ops web runtime llm project_setup docs infra],
  "source" => %w[chat manual_test review trace user_report implementation]
}
required = %w[id title status kind severity priority scope tags source reported_at commits]
terminal_resolutions = %w[fixed wont_do duplicate obsolete moved answered]
errors = []

def frontmatter(path)
  text = File.read(path)
  unless text.start_with?("---\n")
    return [{}, "missing opening frontmatter fence"]
  end
  parts = text.split(/^---\s*$/, 3)
  return [{}, "missing closing frontmatter fence"] if parts.length < 3

  data = parts[1].to_s.lines.each_with_object({}) do |line, memo|
    key, value = line.split(":", 2)
    next unless key && value
    memo[key.strip] = value.strip
  end
  [data, nil]
end

Dir[ticket_glob].sort.each do |path|
  rel = path.sub("#{root}/", "")
  meta, error = frontmatter(path)
  if error
    errors << "#{rel}: #{error}"
    next
  end

  required.each do |field|
    errors << "#{rel}: missing #{field}" unless meta.key?(field)
  end

  allowed.each do |field, values|
    value = meta[field].to_s
    next if value.empty? && field != "status"
    errors << "#{rel}: invalid #{field}=#{value.inspect}" unless values.include?(value)
  end

  dir_status = File.basename(File.dirname(path))
  errors << "#{rel}: status #{meta['status'].inspect} does not match directory #{dir_status.inspect}" unless meta["status"] == dir_status

  timestamp = File.basename(path)[/^(\d{14})-/, 1]
  errors << "#{rel}: filename must start with YYYYMMDDHHMMSS-" unless timestamp
  errors << "#{rel}: id must be TKT-#{timestamp}" if timestamp && meta["id"] != "TKT-#{timestamp}"

  tags = meta.fetch("tags", "").split(",").map(&:strip).reject(&:empty?)
  errors << "#{rel}: tags must contain at most 5 values" if tags.length > 5
  tags.each do |tag|
    errors << "#{rel}: tag #{tag.inspect} should be lowercase kebab-case" unless tag.match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
  end

  if %w[solved closed].include?(meta["status"])
    errors << "#{rel}: terminal ticket must set closed_at" if meta.fetch("closed_at", "").empty?
    resolution = meta.fetch("resolution", "")
    errors << "#{rel}: terminal ticket must set valid resolution" unless terminal_resolutions.include?(resolution)
  end
end

if errors.empty?
  puts "ticket checks passed"
else
  warn errors.join("\n")
  exit 1
end
RUBY
