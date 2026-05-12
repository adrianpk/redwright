# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/codex_proof/input_packet"

class CodexProofInputPacketTest < Minitest::Test
  def test_accepts_valid_ticket_like_packet
    packet = Redwright::CodexProof::InputPacket.new(
      "schema_version" => 1,
      "repository_url" => "https://codeberg.org/example/go-todo-agent.git",
      "result_branch" => "codex/mark-as-read",
      "task_prompt" => "Implement a user-facing mark-as-read capability in the Go todo CLI and include tests for the new behavior.",
      "validation_command" => "go test ./...",
      "output_directory" => "tmp/codex-proof/run-1/output",
      "remote_push_policy" => {
        "enabled" => true,
        "remote" => "origin",
        "branch" => "codex/mark-as-read"
      }
    )

    assert(packet.valid?)
    assert_empty(packet.errors)
    assert_equal("codex/mark-as-read", packet.to_h.dig("remote_push_policy", "branch"))
  end

  def test_rejects_missing_required_fields
    packet = Redwright::CodexProof::InputPacket.new(
      "schema_version" => 1,
      "remote_push_policy" => { "enabled" => true }
    )

    refute(packet.valid?)
    assert_includes(packet.errors, "repository_url_required")
    assert_includes(packet.errors, "result_branch_required")
    assert_includes(packet.errors, "task_prompt_required")
    assert_includes(packet.errors, "validation_command_required")
    assert_includes(packet.errors, "output_directory_required")
  end

  def test_rejects_disabled_remote_push_policy
    packet = Redwright::CodexProof::InputPacket.new(
      "schema_version" => 1,
      "repository_url" => "https://codeberg.org/example/go-todo-agent.git",
      "result_branch" => "codex/mark-as-read",
      "task_prompt" => "Implement a user-facing mark-as-read capability in the Go todo CLI and include tests.",
      "validation_command" => "go test ./...",
      "output_directory" => "tmp/codex-proof/run-1/output",
      "remote_push_policy" => { "enabled" => false }
    )

    refute(packet.valid?)
    assert_includes(packet.errors, "remote_push_policy_enabled_required")
  end
end
