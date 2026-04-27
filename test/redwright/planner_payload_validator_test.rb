# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/planner_payload_validator"

class PlannerPayloadValidatorTest < Minitest::Test
  def test_validate_accepts_valid_payload
    validator = Redwright::PlannerPayloadValidator.new
    payload = JSON.generate(
      {
        intent: "change",
        message: "update README with setup steps",
        actions: [
          {
            id: "a1",
            type: "read_file",
            args: { path: "README.md" },
            requires_confirmation: false,
            timeout_ms: 10_000,
            on_failure: "abort"
          }
        ]
      }
    )

    result = validator.validate(payload)
    assert_equal(true, result.valid)
    assert_equal("change", result.intent)
    assert_equal("update README with setup steps", result.message)
    assert_empty(result.errors)
  end

  def test_validate_rejects_invalid_payload
    validator = Redwright::PlannerPayloadValidator.new
    payload = JSON.generate(
      {
        intent: "weird",
        message: "",
        actions: [
          {
            id: "",
            type: "",
            args: [],
            requires_confirmation: "no",
            timeout_ms: 0,
            on_failure: "maybe"
          }
        ],
        extra: "not-allowed"
      }
    )

    result = validator.validate(payload)
    assert_equal(false, result.valid)
    refute_empty(result.errors)
    assert_includes(result.errors.join("|"), "intent_not_allowed")
    assert_includes(result.errors.join("|"), "message_empty")
    assert_includes(result.errors.join("|"), "top_level_extra_keys:extra")
    assert_includes(result.errors.join("|"), "action_0_args_not_object")
    assert_includes(result.errors.join("|"), "action_0_on_failure_not_allowed")
  end

  def test_validate_rejects_partial_payload
    validator = Redwright::PlannerPayloadValidator.new
    payload = JSON.generate(
      {
        intent: "meta",
        actions: []
      }
    )

    result = validator.validate(payload)
    assert_equal(false, result.valid)
    assert_includes(result.errors.join("|"), "top_level_missing_keys:message")
  end
end
