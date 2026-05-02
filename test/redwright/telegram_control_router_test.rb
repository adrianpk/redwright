# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/telegram_control_router"

class TelegramControlRouterTest < Minitest::Test
  Decision = Struct.new(:control_intent, :intent, :operational_intent, keyword_init: true)

  def setup
    @router = Redwright::TelegramControlRouter.new
  end

  def test_parse_slash_command_covers_primary_operational_and_control_paths
    assert_equal({ kind: "control", command: "pause", reason: "/pause" }, @router.parse_slash_command("/pause"))
    assert_equal({ kind: "control", command: "resume", reason: "/resume" }, @router.parse_slash_command("/resume"))
    assert_equal({ kind: "control", command: "stop", reason: "/cancel" }, @router.parse_slash_command("/cancel"))

    assert_equal("project_switch", @router.parse_slash_command("/project switch rw")[:command])
    assert_equal("project_list", @router.parse_slash_command("/project list")[:command])
    assert_equal("project_where", @router.parse_slash_command("/project where")[:command])
    assert_equal("planner_hint", @router.parse_slash_command("/project new hello")[:kind])
    assert_equal("clarify", @router.parse_slash_command("/project new")[:kind])

    assert_equal("repo_clone", @router.parse_slash_command("/repo clone https://example.com/acme/rw.git")[:command])
    assert_equal("repo_status", @router.parse_slash_command("/repo status")[:command])
    assert_equal("repo_undo", @router.parse_slash_command("/repo undo")[:command])

    assert_equal("ticket_list", @router.parse_slash_command("/ticket list")[:command])
    assert_equal("ticket_pick", @router.parse_slash_command("/ticket pick")[:command])
    assert_equal("ticket_start", @router.parse_slash_command("/ticket start task-1")[:command])
    assert_equal("loop_start", @router.parse_slash_command("/loop start")[:command])
    assert_equal("loop_stop", @router.parse_slash_command("/loop stop")[:command])

    assert_equal("planner_hint", @router.parse_slash_command("/plan start")[:kind])
    assert_equal("planner_hint", @router.parse_slash_command("/trace on")[:kind])
    assert_equal("planner_hint", @router.parse_slash_command("/help")[:kind])
    assert_equal("planner_hint", @router.parse_slash_command("/skills")[:kind])
    assert_equal("skill", @router.parse_slash_command("/skill repo-bootstrap")[:kind])
    assert_equal("skill_control_stop", @router.parse_slash_command("/skill stop-and-apply")[:kind])
    assert_nil(@router.parse_slash_command("/unknown cmd"))
  end

  def test_control_from_decision_and_operational_mappings
    pause = @router.control_from_decision(Decision.new(control_intent: "task_pause", intent: "meta"), raw_text: "pause now")
    assert_nil(pause)

    proceed_meta = @router.control_from_decision(Decision.new(control_intent: "proceed_with_current_context", intent: "meta"), raw_text: "continue")
    assert_equal("resume", proceed_meta[:command])

    proceed_change = @router.control_from_decision(Decision.new(control_intent: "proceed_with_current_context", intent: "change"), raw_text: "continue")
    assert_nil(proceed_change)

    inferred_stop = @router.control_from_decision(Decision.new(control_intent: "none", intent: "meta"), raw_text: "cancel all")
    assert_equal("stop", inferred_stop[:command])

    inferred_pause = @router.control_from_decision(Decision.new(control_intent: "none", intent: "meta"), raw_text: "pausa")
    assert_equal("pause", inferred_pause[:command])

    inferred_resume = @router.control_from_decision(Decision.new(control_intent: "none", intent: "meta"), raw_text: "continua")
    assert_equal("resume", inferred_resume[:command])

    op_pause = @router.control_from_operational(Decision.new(control_intent: "none", operational_intent: "task_pause"), raw_text: "/task pause")
    assert_equal("pause", op_pause[:command])

    op_resume = @router.control_from_operational(Decision.new(control_intent: "none", operational_intent: "plan_continue"), raw_text: "/plan continue")
    assert_equal("resume", op_resume[:command])

    op_stop = @router.control_from_operational(Decision.new(control_intent: "none", operational_intent: "task_cancel"), raw_text: "/task cancel")
    assert_equal("stop", op_stop[:command])

    blocked = @router.control_from_operational(Decision.new(control_intent: "cancel_task", operational_intent: "task_pause"), raw_text: "x")
    assert_nil(blocked)
  end
end
