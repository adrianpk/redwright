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
end
