# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/action_normalizer"

class ActionNormalizerTest < Minitest::Test
  def test_expand_write_files_into_ordered_write_file_actions
    normalizer = Redwright::ActionNormalizer.new
    actions = [
      {
        "id" => "wf",
        "type" => "write_files",
        "args" => {
          "files" => {
            "b.txt" => "B",
            "a.txt" => "A"
          }
        },
        "requires_confirmation" => false,
        "timeout_ms" => 10_000,
        "on_failure" => "abort"
      }
    ]

    normalized = normalizer.normalize(actions)
    assert_equal(2, normalized.size)
    assert_equal("wf.1", normalized[0]["id"])
    assert_equal("wf.2", normalized[1]["id"])
    assert_equal("write_file", normalized[0]["type"])
    assert_equal("a.txt", normalized[0].dig("args", "path"))
    assert_equal("A", normalized[0].dig("args", "content"))
    assert_equal("b.txt", normalized[1].dig("args", "path"))
    assert_equal("B", normalized[1].dig("args", "content"))
  end

  def test_expand_run_command_into_single_run
    normalizer = Redwright::ActionNormalizer.new
    normalized = normalizer.normalize(
      [
        {
          "id" => "cmd",
          "type" => "run_command",
          "args" => { "cmd" => "echo hello" },
          "requires_confirmation" => false,
          "timeout_ms" => 10_000,
          "on_failure" => "abort"
        }
      ]
    )

    assert_equal(1, normalized.size)
    assert_equal("cmd", normalized[0]["id"])
    assert_equal("run", normalized[0]["type"])
    assert_equal("echo hello", normalized[0].dig("args", "command"))
  end

  def test_expand_run_commands_into_run_sequence
    normalizer = Redwright::ActionNormalizer.new
    normalized = normalizer.normalize(
      [
        {
          "id" => "cmds",
          "type" => "run_commands",
          "args" => { "cmds" => ["echo one", "echo two"] },
          "requires_confirmation" => false,
          "timeout_ms" => 10_000,
          "on_failure" => "continue"
        }
      ]
    )

    assert_equal(2, normalized.size)
    assert_equal("cmds.1", normalized[0]["id"])
    assert_equal("cmds.2", normalized[1]["id"])
    assert_equal("run", normalized[0]["type"])
    assert_equal("echo one", normalized[0].dig("args", "command"))
    assert_equal("echo two", normalized[1].dig("args", "command"))
    assert_equal("continue", normalized[0]["on_failure"])
    assert_equal("continue", normalized[1]["on_failure"])
  end
end
