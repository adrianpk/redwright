# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/telegram_control_router"

class TelegramControlRouterTest < Minitest::Test
  FakeDecision = Struct.new(
    :control_intent,
    :intent,
    :operational_intent,
    keyword_init: true
  )

  def setup
    @router = Redwright::TelegramControlRouter.new
  end

  def test_control_from_decision_maps_explicit_control_intent
    decision = FakeDecision.new(control_intent: "cancel_task", intent: "change")
    result = @router.control_from_decision(decision, raw_text: "cancel this")

    assert_equal({ command: "stop", reason: "cancel this" }, result)
  end

  def test_control_from_decision_ignores_proceed_on_non_meta_intent
    decision = FakeDecision.new(control_intent: "proceed_with_current_context", intent: "change")
    assert_nil(@router.control_from_decision(decision, raw_text: "continue"))
  end

  def test_control_from_decision_infers_control_only_for_meta_intent
    decision = FakeDecision.new(control_intent: "none", intent: "meta")

    assert_equal("pause", @router.control_from_decision(decision, raw_text: "pausa")[:command])
    assert_equal("resume", @router.control_from_decision(decision, raw_text: "continue")[:command])
    assert_equal("stop", @router.control_from_decision(decision, raw_text: "cancelar")[:command])
    assert_nil(@router.control_from_decision(decision, raw_text: "do work"))
  end

  def test_control_from_operational_maps_known_operational_intents
    assert_equal("pause", @router.control_from_operational(FakeDecision.new(operational_intent: "task_pause"), raw_text: "x")[:command])
    assert_equal("resume", @router.control_from_operational(FakeDecision.new(operational_intent: "task_resume"), raw_text: "x")[:command])
    assert_equal("stop", @router.control_from_operational(FakeDecision.new(operational_intent: "task_cancel"), raw_text: "x")[:command])
    assert_equal("resume", @router.control_from_operational(FakeDecision.new(operational_intent: "plan_continue"), raw_text: "x")[:command])
    assert_equal("resume", @router.control_from_operational(FakeDecision.new(operational_intent: "plan_stop_and_apply"), raw_text: "x")[:command])
  end

  def test_control_from_operational_returns_nil_when_control_intent_is_present
    decision = FakeDecision.new(control_intent: "cancel_task", operational_intent: "task_pause")
    assert_nil(@router.control_from_operational(decision, raw_text: "x"))
  end

  def test_parse_slash_command_handles_control_and_planner_hints
    assert_equal("control", @router.parse_slash_command("/pause")[:kind])
    assert_equal("resume", @router.parse_slash_command("/resume")[:command])
    assert_equal("stop", @router.parse_slash_command("/cancel")[:command])
    assert_equal("planner_hint", @router.parse_slash_command("/continue")[:kind])
    assert_equal("planner_hint", @router.parse_slash_command("/status")[:kind])
  end

  def test_parse_slash_command_handles_project_repo_task_loop_and_skill_commands
    assert_equal("clarify", @router.parse_slash_command("/project new")[:kind])
    assert_equal("project_switch", @router.parse_slash_command("/project switch alpha")[:command])
    assert_equal("project_list", @router.parse_slash_command("/project list")[:command])
    assert_equal("project_where", @router.parse_slash_command("/project where")[:command])

    assert_equal("repo_clone", @router.parse_slash_command("/repo clone https://example.com/acme/repo.git")[:command])
    assert_equal("repo_status", @router.parse_slash_command("/repo status")[:command])
    assert_equal("repo_undo", @router.parse_slash_command("/repo undo")[:command])

    assert_equal("ticket_list", @router.parse_slash_command("/ticket list")[:command])
    assert_equal("ticket_pick", @router.parse_slash_command("/ticket pick")[:command])
    assert_equal("ticket_start", @router.parse_slash_command("/ticket start tk-1")[:command])

    assert_equal("loop_start", @router.parse_slash_command("/loop start")[:command])
    assert_equal("loop_stop", @router.parse_slash_command("/loop stop")[:command])

    assert_equal("skill_control_stop", @router.parse_slash_command("/skill stop-and-apply")[:kind])
    assert_equal("skill", @router.parse_slash_command("/skill repo-bootstrap")[:kind])
  end
end
