# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/planner_payload_validator"

class PlannerPayloadValidatorTest < Minitest::Test
  def test_validate_accepts_valid_payload
    validator = Redwright::PlannerPayloadValidator.new
    payload = JSON.generate(
      base_payload.merge(
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
      )
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
      base_payload.merge(
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
      )
    )

    result = validator.validate(payload)
    assert_equal(false, result.valid)
    assert(result.errors.any? { |e| e.start_with?("schema_enum_mismatch:$.intent") })
    assert(result.errors.any? { |e| e.start_with?("schema_min_length:$.message") })
    assert_includes(result.errors, "schema_extra_key:$.extra")
  end

  def test_validate_rejects_partial_payload
    validator = Redwright::PlannerPayloadValidator.new
    payload = JSON.generate({ intent: "meta", message: "x", actions: [] })

    result = validator.validate(payload)
    assert_equal(false, result.valid)
    assert_includes(result.errors, "schema_missing_key:$.gaps")
  end

  def test_validate_accepts_macro_action_type
    validator = Redwright::PlannerPayloadValidator.new
    payload = JSON.generate(
      base_payload.merge(
        message: "write multiple files",
        actions: [
          {
            id: "a1",
            type: "write_files",
            args: { files: { "a.txt" => "x" } },
            requires_confirmation: false,
            timeout_ms: 10_000,
            on_failure: "abort"
          }
        ]
      )
    )

    result = validator.validate(payload)
    assert_equal(true, result.valid)
  end

  def test_validate_accepts_write_files_array_shape
    validator = Redwright::PlannerPayloadValidator.new
    payload = JSON.generate(
      base_payload.merge(
        message: "write multiple files",
        actions: [
          {
            id: "a1",
            type: "write_files",
            args: { files: [{ path: "a.txt", content: "x" }] },
            requires_confirmation: false,
            timeout_ms: 10_000,
            on_failure: "abort"
          }
        ]
      )
    )

    result = validator.validate(payload)
    assert_equal(true, result.valid)
  end

  def test_validate_rejects_unknown_action_type
    validator = Redwright::PlannerPayloadValidator.new
    payload = JSON.generate(
      base_payload.merge(
        message: "do unknown thing",
        actions: [
          {
            id: "a1",
            type: "unknown_action_type",
            args: {},
            requires_confirmation: false,
            timeout_ms: 10_000,
            on_failure: "abort"
          }
        ]
      )
    )

    result = validator.validate(payload)
    assert_equal(false, result.valid)
    assert(result.errors.any? { |e| e.start_with?("schema_enum_mismatch:$.actions[0].type") })
  end

  def test_validate_rejects_invalid_control_intent
    validator = Redwright::PlannerPayloadValidator.new
    payload = JSON.generate(base_payload.merge(intent: "meta", control_intent: "unknown_control"))

    result = validator.validate(payload)
    assert_equal(false, result.valid)
    assert(result.errors.any? { |e| e.start_with?("schema_enum_mismatch:$.control_intent") })
  end

  def test_validate_rejects_operational_and_control_conflict
    validator = Redwright::PlannerPayloadValidator.new
    payload = JSON.generate(
      base_payload.merge(
        intent: "meta",
        control_intent: "cancel_task",
        control_scope: "task",
        operational_intent: "project_switch",
        operational_scope: "project",
        operational_args: { project_ref: "rw" }
      )
    )

    result = validator.validate(payload)
    assert_equal(false, result.valid)
    assert_includes(result.errors, "taxonomy_conflict:control_and_operational_intents")
  end

  def test_validate_rejects_operational_intent_without_scope
    validator = Redwright::PlannerPayloadValidator.new
    payload = JSON.generate(
      base_payload.merge(
        intent: "meta",
        operational_intent: "project_list",
        operational_scope: "none"
      )
    )

    result = validator.validate(payload)
    assert_equal(false, result.valid)
    assert_includes(result.errors, "taxonomy_missing_scope_for_operational_intent")
  end

  def test_validate_rejects_missing_project_ref_when_operational_requires_project
    validator = Redwright::PlannerPayloadValidator.new
    payload = JSON.generate(
      base_payload.merge(
        intent: "meta",
        operational_intent: "repo_status",
        operational_scope: "project",
        operational_requires_project: true,
        operational_args: {}
      )
    )

    result = validator.validate(payload)
    assert_equal(false, result.valid)
    assert_includes(result.errors, "taxonomy_missing_operational_project_ref")
  end

  def test_validate_accepts_legacy_payload_without_operational_fields
    validator = Redwright::PlannerPayloadValidator.new
    payload = JSON.generate(
      {
        intent: "change",
        message: "legacy payload",
        actions: [],
        gaps: []
      }
    )

    result = validator.validate(payload)
    assert_equal(true, result.valid)
    assert_equal("none", result.operational_intent)
    assert_equal("none", result.control_intent)
  end

  private

  def base_payload
    {
      intent: "change",
      message: "x",
      actions: [],
      gaps: [],
      control_intent: "none",
      control_scope: "none",
      operational_intent: "none",
      operational_scope: "none",
      operational_args: {},
      operational_requires_project: false,
      operational_requires_confirmation: false,
      skill_requested: "",
      skill_mode: "none",
      skill_actions: [],
      skill_exit_condition: ""
    }
  end
end
