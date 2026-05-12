# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/codex_proof/harness"

class CodexProofHarnessTest < Minitest::Test
  FixedClock = Struct.new(:now)

  def test_prepare_creates_run_directory_and_normalized_packet
    Dir.mktmpdir("codex-proof-harness-") do |dir|
      packet = Redwright::CodexProof::InputPacket.new(valid_packet("output"))
      clock = FixedClock.new(Time.utc(2026, 5, 12, 10, 30, 0))
      harness = Redwright::CodexProof::Harness.new(
        packet: packet,
        runs_root: dir,
        clock: clock,
        id_generator: -> { "abcd1234" }
      )

      result = harness.prepare

      assert_equal("prepared", result.fetch("status"))
      assert_equal("codex-proof-20260512103000-abcd1234", result.fetch("run_id"))
      assert(File.directory?(result.fetch("run_directory")))
      assert(File.directory?(result.fetch("output_directory")))
      assert(File.file?(result.fetch("input_packet")))

      normalized = JSON.parse(File.read(result.fetch("input_packet")))
      assert_equal(result.fetch("run_id"), normalized.fetch("run_id"))
      assert_equal(result.fetch("run_directory"), normalized.fetch("run_directory"))
      assert_equal(result.fetch("output_directory"), normalized.fetch("output_directory"))
      assert_equal("https://codeberg.org/example/go-todo-agent.git", normalized.fetch("repository_url"))
    end
  end

  def test_prepare_expands_run_id_in_result_branch
    Dir.mktmpdir("codex-proof-harness-") do |dir|
      packet_data = valid_packet("output")
      packet_data["result_branch"] = "redwright/codex-proof/{run_id}"
      packet_data["remote_push_policy"]["branch"] = "redwright/codex-proof/{run_id}"
      packet = Redwright::CodexProof::InputPacket.new(packet_data)
      clock = FixedClock.new(Time.utc(2026, 5, 12, 10, 30, 0))
      harness = Redwright::CodexProof::Harness.new(
        packet: packet,
        runs_root: dir,
        clock: clock,
        id_generator: -> { "abcd1234" }
      )

      result = harness.prepare
      normalized = JSON.parse(File.read(result.fetch("input_packet")))

      assert_equal("redwright/codex-proof/codex-proof-20260512103000-abcd1234", normalized.fetch("result_branch"))
      assert_equal("redwright/codex-proof/codex-proof-20260512103000-abcd1234", normalized.dig("remote_push_policy", "branch"))
    end
  end

  def test_prepare_returns_invalid_input_without_creating_run
    Dir.mktmpdir("codex-proof-harness-") do |dir|
      packet = Redwright::CodexProof::InputPacket.new({})

      result = Redwright::CodexProof::Harness.new(packet: packet, runs_root: dir).prepare

      assert_equal("invalid_input", result.fetch("status"))
      assert_includes(result.fetch("errors"), "repository_url_required")
      assert_empty(Dir.children(dir))
    end
  end

  private

  def valid_packet(output_directory)
    {
      "schema_version" => 1,
      "repository_url" => "https://codeberg.org/example/go-todo-agent.git",
      "result_branch" => "codex/mark-as-read",
      "task_prompt" => "Implement a user-facing mark-as-read capability in the Go todo CLI and include tests for the new behavior.",
      "validation_command" => "go test ./...",
      "output_directory" => output_directory,
      "remote_push_policy" => {
        "enabled" => true,
        "remote" => "origin",
        "branch" => "codex/mark-as-read"
      }
    }
  end
end
