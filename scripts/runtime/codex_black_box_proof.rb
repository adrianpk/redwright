#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "optparse"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))

require "redwright/codex_proof/harness"

options = {
  runs_root: File.expand_path("../../tmp/codex-proof/runs", __dir__)
}

parser = OptionParser.new do |opts|
  opts.banner = "usage: scripts/runtime/codex_black_box_proof.rb --packet PATH [--runs-root PATH]"
  opts.on("--packet PATH", "Path to the proof input packet JSON file") { |value| options[:packet] = value }
  opts.on("--runs-root PATH", "Directory where proof run directories are created") { |value| options[:runs_root] = value }
end

parser.parse!(ARGV)

unless options[:packet]
  warn(parser.to_s)
  exit 2
end

packet = Redwright::CodexProof::InputPacket.from_json_file(options.fetch(:packet))
result = Redwright::CodexProof::Harness.new(
  packet: packet,
  runs_root: options.fetch(:runs_root)
).prepare

puts(JSON.pretty_generate(result))
exit(result.fetch("status") == "prepared" ? 0 : 2)
