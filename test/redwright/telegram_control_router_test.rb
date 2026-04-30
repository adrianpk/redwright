# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/telegram_control_router"

class TelegramControlRouterTest < Minitest::Test
  FakeDecision = Struct.new(:intent, :control_intent, :operational_intent, keyword_init: true)

  def test_parse_slash_command_returns_control_for_cancel
    parsed = Redwright::TelegramControlRouter.new.parse_slash_command("/cancel")
    assert_equal("control", parsed[:kind])
    assert_equal("stop", parsed[:command])
  end

  def test_parse_slash_command_clarifies_project_new_without_name
    parsed = Redwright::TelegramControlRouter.new.parse_slash_command("/project new")
    assert_equal("clarify", parsed[:kind])
    assert_match("/project new <name>", parsed[:question])
  end

  def test_parse_slash_command_routes_project_switch_as_operational
    parsed = Redwright::TelegramControlRouter.new.parse_slash_command("/project switch alpha")
    assert_equal("operational", parsed[:kind])
    assert_equal("project_switch", parsed[:command])
  end

  def test_parse_slash_command_routes_project_new_with_text_to_planner_hint
    parsed = Redwright::TelegramControlRouter.new.parse_slash_command("/project new create a go app")
    assert_equal("planner_hint", parsed[:kind])
    assert_includes(parsed[:planner_text], "Create a new project.")
    assert_includes(parsed[:planner_text], "create a go app")
  end

  def test_parse_slash_command_routes_repo_clone_as_operational
    parsed = Redwright::TelegramControlRouter.new.parse_slash_command("/repo clone https://example.com/acme/repo.git")
    assert_equal("operational", parsed[:kind])
    assert_equal("repo_clone", parsed[:command])
  end

  def test_parse_slash_command_routes_project_list_as_operational
    parsed = Redwright::TelegramControlRouter.new.parse_slash_command("/project list")
    assert_equal("operational", parsed[:kind])
    assert_equal("project_list", parsed[:command])
  end

  def test_parse_slash_command_routes_repo_status_as_operational
    parsed = Redwright::TelegramControlRouter.new.parse_slash_command("/repo status")
    assert_equal("operational", parsed[:kind])
    assert_equal("repo_status", parsed[:command])
  end

  def test_parse_slash_command_routes_ticket_list_as_operational
    parsed = Redwright::TelegramControlRouter.new.parse_slash_command("/ticket list")
    assert_equal("operational", parsed[:kind])
    assert_equal("ticket_list", parsed[:command])
  end

  def test_parse_slash_command_routes_loop_start_as_operational
    parsed = Redwright::TelegramControlRouter.new.parse_slash_command("/loop start")
    assert_equal("operational", parsed[:kind])
    assert_equal("loop_start", parsed[:command])
  end

  def test_control_from_decision_maps_meta_cancel
    router = Redwright::TelegramControlRouter.new
    control = router.control_from_decision(
      FakeDecision.new(intent: "meta", control_intent: "cancel_task"),
      raw_text: "cancelar"
    )
    assert_equal("stop", control[:command])
  end

  def test_control_from_operational_maps_plan_stop_and_apply_to_resume
    router = Redwright::TelegramControlRouter.new
    control = router.control_from_operational(
      FakeDecision.new(operational_intent: "plan_stop_and_apply"),
      raw_text: "continue"
    )
    assert_equal("resume", control[:command])
  end

  def test_control_from_decision_accepts_explicit_control_even_without_meta_intent
    router = Redwright::TelegramControlRouter.new
    control = router.control_from_decision(
      FakeDecision.new(intent: "change", control_intent: "cancel_task"),
      raw_text: "continue coding but cancel current task"
    )
    assert_equal("stop", control[:command])
  end

  def test_control_from_operational_is_ignored_when_control_intent_is_present
    router = Redwright::TelegramControlRouter.new
    control = router.control_from_operational(
      FakeDecision.new(control_intent: "cancel_task", operational_intent: "task_resume"),
      raw_text: "resume"
    )
    assert_nil(control)
  end
end
