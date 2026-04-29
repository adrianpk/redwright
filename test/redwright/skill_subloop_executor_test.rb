# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/skill_subloop_executor"

class SkillSubloopExecutorTest < Minitest::Test
  def test_run_finishes_successfully
    executor = Redwright::SkillSubloopExecutor.new(max_attempts: 4, max_seconds: 10, monotonic_clock: -> { 0.0 })
    seen = 0

    result = executor.run(actions: [{ "id" => "a1" }, { "id" => "a2" }]) do |_action|
      seen += 1
      { status: "ok" }
    end

    assert_equal("ok", result.status)
    assert_equal("success", result.terminal_reason)
    assert_equal(2, result.attempts)
    assert_equal(2, result.executed_actions)
    assert_equal(2, seen)
  end

  def test_run_stops_on_timeout
    ticks = [0.0, 100.0, 100.0]
    executor = Redwright::SkillSubloopExecutor.new(max_attempts: 4, max_seconds: 1, monotonic_clock: -> { ticks.shift || 100.0 })

    result = executor.run(actions: [{ "id" => "a1" }]) { |_action| { status: "ok" } }

    assert_equal("error", result.status)
    assert_equal("timeout", result.terminal_reason)
    assert_equal(0, result.attempts)
    assert_equal(0, result.executed_actions)
  end

  def test_run_stops_on_cancel
    executor = Redwright::SkillSubloopExecutor.new(max_attempts: 4, max_seconds: 10, monotonic_clock: -> { 0.0 })

    result = executor.run(
      actions: [{ "id" => "a1" }],
      cancel_requested: -> { true }
    ) { |_action| { status: "ok" } }

    assert_equal("error", result.status)
    assert_equal("canceled", result.terminal_reason)
    assert_equal(0, result.attempts)
    assert_equal(0, result.executed_actions)
  end
end
