#!/usr/bin/env bash
set -euo pipefail

# Search or list repository-local RedWright development tickets.
#
# Common usage:
#   scripts/agent/tickets/search.sh
#   scripts/agent/tickets/search.sh markdown
#   scripts/agent/tickets/search.sh --status open --tag web
#   scripts/agent/tickets/search.sh comments --status open --format paths
#
# Search matches filename, title, tags, scope, kind, status, and body text.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
QUERY=""
STATUS=""
TAG=""
KIND=""
SCOPE=""
FORMAT="table"

usage() {
  cat <<'USAGE'
Usage: scripts/agent/tickets/search.sh [query] [options]

Lists or searches tickets under ops/tickets/.

Options:
  --status VALUE     Filter by status directory/frontmatter.
  --tag VALUE        Filter by one tag.
  --kind VALUE       Filter by kind.
  --scope VALUE      Filter by scope.
  --format FORMAT    table|paths|long. Default: table.
  -h, --help         Show this help.

Examples:
  scripts/agent/tickets/search.sh
  scripts/agent/tickets/search.sh markdown
  scripts/agent/tickets/search.sh --status open --tag web
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --status)
      STATUS="${2:-}"
      [[ -n "$STATUS" ]] || { echo "missing value for --status" >&2; exit 2; }
      shift 2
      ;;
    --tag)
      TAG="${2:-}"
      [[ -n "$TAG" ]] || { echo "missing value for --tag" >&2; exit 2; }
      shift 2
      ;;
    --kind)
      KIND="${2:-}"
      [[ -n "$KIND" ]] || { echo "missing value for --kind" >&2; exit 2; }
      shift 2
      ;;
    --scope)
      SCOPE="${2:-}"
      [[ -n "$SCOPE" ]] || { echo "missing value for --scope" >&2; exit 2; }
      shift 2
      ;;
    --format)
      FORMAT="${2:-}"
      [[ "$FORMAT" == "table" || "$FORMAT" == "paths" || "$FORMAT" == "long" ]] || {
        echo "--format must be table, paths, or long" >&2
        exit 2
      }
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
      if [[ -z "$QUERY" ]]; then
        QUERY="$1"
      else
        echo "unexpected extra argument: $1" >&2
        usage >&2
        exit 2
      fi
      shift
      ;;
  esac
done

export ROOT_DIR QUERY STATUS TAG KIND SCOPE FORMAT

ruby <<'RUBY'
root = ENV.fetch("ROOT_DIR")
query = ENV.fetch("QUERY").downcase
status_filter = ENV.fetch("STATUS")
tag_filter = ENV.fetch("TAG")
kind_filter = ENV.fetch("KIND")
scope_filter = ENV.fetch("SCOPE")
format = ENV.fetch("FORMAT")

def frontmatter(text)
  return {} unless text.start_with?("---\n")
  raw = text.split(/^---\s*$/, 3)[1].to_s
  raw.lines.each_with_object({}) do |line, data|
    key, value = line.split(":", 2)
    next unless key && value
    data[key.strip] = value.strip
  end
end

tickets = Dir[File.join(root, "ops/tickets/{open,ready,in_progress,reviewing,blocked,solved,closed}/*.md")].sort.filter_map do |path|
  text = File.read(path)
  meta = frontmatter(text)
  status_dir = File.basename(File.dirname(path))
  tags = meta.fetch("tags", "").split(",").map(&:strip).reject(&:empty?)
  haystack = [
    path,
    meta["id"],
    meta["title"],
    meta["status"],
    meta["kind"],
    meta["scope"],
    meta["tags"],
    text
  ].compact.join("\n").downcase

  next if !query.empty? && !haystack.include?(query)
  next if !status_filter.empty? && meta["status"] != status_filter && status_dir != status_filter
  next if !tag_filter.empty? && !tags.include?(tag_filter)
  next if !kind_filter.empty? && meta["kind"] != kind_filter
  next if !scope_filter.empty? && meta["scope"] != scope_filter

  {
    path: path.sub("#{root}/", ""),
    id: meta["id"].to_s,
    title: meta["title"].to_s,
    status: meta["status"].to_s,
    kind: meta["kind"].to_s,
    priority: meta["priority"].to_s,
    scope: meta["scope"].to_s,
    tags: tags.join(", ")
  }
end

case format
when "paths"
  puts tickets.map { |ticket| ticket[:path] }
when "long"
  tickets.each do |ticket|
    puts "#{ticket[:id]} #{ticket[:title]}"
    puts "  status: #{ticket[:status]}"
    puts "  kind: #{ticket[:kind]}"
    puts "  priority: #{ticket[:priority]}"
    puts "  scope: #{ticket[:scope]}"
    puts "  tags: #{ticket[:tags]}"
    puts "  path: #{ticket[:path]}"
  end
else
  widths = {
    id: [tickets.map { |ticket| ticket[:id].length }.max || 2, 2].max,
    status: [tickets.map { |ticket| ticket[:status].length }.max || 6, 6].max,
    kind: [tickets.map { |ticket| ticket[:kind].length }.max || 4, 4].max,
    priority: [tickets.map { |ticket| ticket[:priority].length }.max || 8, 8].max
  }
  puts format("%-#{widths[:id]}s  %-#{widths[:status]}s  %-#{widths[:kind]}s  %-#{widths[:priority]}s  %s", "ID", "STATUS", "KIND", "PRIORITY", "TITLE")
  tickets.each do |ticket|
    puts format(
      "%-#{widths[:id]}s  %-#{widths[:status]}s  %-#{widths[:kind]}s  %-#{widths[:priority]}s  %s",
      ticket[:id],
      ticket[:status],
      ticket[:kind],
      ticket[:priority],
      ticket[:title]
    )
  end
end
RUBY
