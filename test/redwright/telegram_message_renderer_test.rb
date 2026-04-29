# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/telegram_execution_summary"
require "redwright/telegram_message_renderer"

class TelegramMessageRendererTest < Minitest::Test
  FakeProject = Struct.new(:id, keyword_init: true)
  FakeWorkstream = Struct.new(:id, :state, keyword_init: true)
  FakeTask = Struct.new(:id, keyword_init: true)
  FakeAction = Struct.new(:action_id, :status, :error_message, :action_type, keyword_init: true)
  FakeResult = Struct.new(:project, :workstream, :task, :action_results, :terminal_reason, keyword_init: true)

  def test_success_renders_integer_action_counters
    renderer = Redwright::TelegramMessageRenderer.new
    result = FakeResult.new(
      project: FakeProject.new(id: "p1"),
      workstream: FakeWorkstream.new(id: "w1", state: "executing"),
      task: FakeTask.new(id: "t1"),
      action_results: [
        FakeAction.new(action_id: "a1", status: "ok"),
        FakeAction.new(action_id: "a2", status: "error")
      ],
      terminal_reason: "executing"
    )

    text = renderer.success(
      result: result,
      trace_id: "trc-1",
      quality_summary: nil,
      attempts: 1,
      terminal_reason: "single_pass",
      mode: "structured"
    )

    assert_match("Actions: 1 succeeded, 1 failed.", text)
    assert_match("Attempts: 1 (terminal: single_pass).", text)
  end

  def test_success_adds_confirmation_hint_for_git_commit_or_push
    renderer = Redwright::TelegramMessageRenderer.new
    result = FakeResult.new(
      project: FakeProject.new(id: "p1"),
      workstream: FakeWorkstream.new(id: "w1", state: "executing"),
      task: FakeTask.new(id: "t1"),
      action_results: [
        FakeAction.new(action_id: "a7", status: "error", error_message: "confirmation_required", action_type: "git_commit")
      ],
      terminal_reason: "executing"
    )

    text = renderer.success(
      result: result,
      trace_id: "trc-2",
      quality_summary: nil,
      attempts: 1,
      terminal_reason: "single_pass",
      mode: "structured"
    )

    assert_match("confirmation policy", text)
    assert_match("a7", text)
  end
end
