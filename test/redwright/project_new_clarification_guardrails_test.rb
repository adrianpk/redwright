# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/project_new_clarification_guardrails"

class ProjectNewClarificationGuardrailsTest < Minitest::Test
  def test_clarification_status_mapping_for_loop_states
    assert_equal("open", Redwright::ProjectNewClarificationGuardrails.clarification_status_for_loop_state("collecting_context"))
    assert_equal("open", Redwright::ProjectNewClarificationGuardrails.clarification_status_for_loop_state("awaiting_blocking_answers"))
    assert_equal("closed", Redwright::ProjectNewClarificationGuardrails.clarification_status_for_loop_state("ready_to_execute"))
    assert_equal("closed", Redwright::ProjectNewClarificationGuardrails.clarification_status_for_loop_state("done"))
    assert_equal("cancelled", Redwright::ProjectNewClarificationGuardrails.clarification_status_for_loop_state("cancelled"))
    assert_nil(Redwright::ProjectNewClarificationGuardrails.clarification_status_for_loop_state("unknown"))
  end

  def test_guardrails_continue_when_under_threshold_and_not_stagnating
    result = Redwright::ProjectNewClarificationGuardrails.evaluate_guardrails(
      max_question_turns: 4,
      turn_counter: 1,
      unresolved_blocking_slots: %w[stack],
      previous_unresolved_blocking_slots: %w[description stack]
    )

    assert_equal("continue", result[:action])
    assert_equal("none", result[:reason])
  end

  def test_guardrails_fallback_when_max_question_turns_reached
    result = Redwright::ProjectNewClarificationGuardrails.evaluate_guardrails(
      max_question_turns: 3,
      turn_counter: 3,
      unresolved_blocking_slots: %w[stack],
      previous_unresolved_blocking_slots: %w[stack]
    )

    assert_equal("fallback_required", result[:action])
    assert_equal("max_question_turns_reached", result[:reason])
    assert_equal(%w[stack], result[:unresolved_blocking_slots])
  end

  def test_guardrails_fallback_when_stagnation_detected
    result = Redwright::ProjectNewClarificationGuardrails.evaluate_guardrails(
      max_question_turns: 5,
      turn_counter: 2,
      unresolved_blocking_slots: %w[description stack],
      previous_unresolved_blocking_slots: %w[stack description]
    )

    assert_equal("fallback_required", result[:action])
    assert_equal("stagnation_detected", result[:reason])
    assert_equal(%w[description stack], result[:unresolved_blocking_slots])
  end

  def test_fallback_summary_contains_known_context_and_required_decision
    summary = Redwright::ProjectNewClarificationGuardrails.fallback_summary(
      known_context: { "project_name" => "taskmaster", "stack" => "go" },
      unresolved_blocking_slots: %w[description]
    )

    assert_equal("cancel_or_proceed_with_defaults", summary[:required_user_decision])
    assert_equal(%w[description], summary[:unresolved_blocking_slots])
    assert_equal(%w[project_name=taskmaster stack=go], summary[:known_context])
  end

  def test_merge_resolved_fields_carries_forward_previous_values
    merged = Redwright::ProjectNewClarificationGuardrails.merge_resolved_fields(
      previous: { "project_name" => "taskmaster", "stack" => "go" },
      new_fields: { "framework" => "cobra" }
    )

    assert_equal("taskmaster", merged["project_name"])
    assert_equal("go", merged["stack"])
    assert_equal("cobra", merged["framework"])
  end
end
