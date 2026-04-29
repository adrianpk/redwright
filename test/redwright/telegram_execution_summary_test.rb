# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/telegram_execution_summary"

class TelegramExecutionSummaryTest < Minitest::Test
  FakeAction = Struct.new(:action_id, :status, keyword_init: true)
  FakeResult = Struct.new(:action_results, :terminal_reason, keyword_init: true)

  def test_build_returns_zero_counters_when_no_actions
    summary = Redwright::TelegramExecutionSummary.new.build(
      FakeResult.new(action_results: [], terminal_reason: "executing"),
      attempts: 1,
      terminal_reason: "single_pass"
    )

    assert_equal(0, summary[:total_actions])
    assert_equal(0, summary[:succeeded_actions])
    assert_equal(0, summary[:failed_actions])
    assert_equal("executing", summary[:terminal_reason])
  end

  def test_build_counts_success_and_failure
    summary = Redwright::TelegramExecutionSummary.new.build(
      FakeResult.new(
        action_results: [
          FakeAction.new(action_id: "a1", status: "ok"),
          FakeAction.new(action_id: "a2", status: "error")
        ],
        terminal_reason: nil
      ),
      attempts: 2,
      terminal_reason: "timeout",
      mode: "structured"
    )

    assert_equal(2, summary[:total_actions])
    assert_equal(1, summary[:succeeded_actions])
    assert_equal(1, summary[:failed_actions])
    assert_equal(["a2"], summary[:failed_action_ids])
    assert_equal("timeout", summary[:terminal_reason])
    assert_equal("structured", summary[:mode])
  end
end
