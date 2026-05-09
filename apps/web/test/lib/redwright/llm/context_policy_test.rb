# frozen_string_literal: true

require "test_helper"
require File.expand_path("../../../../../../lib/redwright/llm/context_policy", __dir__)

class RedwrightLLMContextPolicyTest < ActiveSupport::TestCase
  test "defines the initial work families" do
    assert_equal(
      %w[
        exploration
        implementation
        modification
        diagnosis
        evaluation
        operation
        planning
        documentation
      ],
      Redwright::LLM::ContextPolicy::WORK_FAMILIES
    )
  end

  test "defines confidence bands" do
    assert_equal %w[high medium low], Redwright::LLM::ContextPolicy::CONFIDENCE_BANDS
  end

  test "recognizes valid families and confidence bands" do
    assert Redwright::LLM::ContextPolicy.valid_work_family?("implementation")
    assert Redwright::LLM::ContextPolicy.valid_confidence?("medium")

    refute Redwright::LLM::ContextPolicy.valid_work_family?("mixed")
    refute Redwright::LLM::ContextPolicy.valid_confidence?("uncertain")
  end

  test "selects fallback policy for low confidence" do
    assert_equal(
      "full_context_fallback",
      Redwright::LLM::ContextPolicy.policy_for(family: "implementation", confidence: "low")
    )
  end

  test "exposes every default policy through the registry" do
    Redwright::LLM::ContextPolicy::WORK_FAMILIES.each do |family|
      policy_name = Redwright::LLM::ContextPolicy.default_policy_for(family)
      policy = Redwright::LLM::ContextPolicy.fetch_policy(policy_name)

      assert_equal policy_name, policy.name
      assert_equal family, policy.work_family
      refute_empty policy.included_layers
      refute policy.fallback?
    end
  end

  test "default policy layers are known context layers" do
    Redwright::LLM::ContextPolicy::WORK_FAMILIES.each do |family|
      policy = Redwright::LLM::ContextPolicy.fetch_policy("#{family}_default")

      assert_empty policy.included_layers - Redwright::LLM::ContextPolicy::ALL_CONTEXT_LAYERS
    end
  end

  test "policy matrix accounts for every family and context layer" do
    matrix = Redwright::LLM::ContextPolicy.context_layer_policy_matrix

    assert_equal Redwright::LLM::ContextPolicy::ALL_CONTEXT_LAYERS, matrix.keys
    matrix.each_value do |family_behaviors|
      assert_equal(
        Redwright::LLM::ContextPolicy::WORK_FAMILIES + [Redwright::LLM::ContextPolicy::FULL_CONTEXT_FALLBACK],
        family_behaviors.keys
      )
      assert_empty family_behaviors.values - %w[included omitted]
    end
  end

  test "policy matrix captures expected tuning baseline" do
    assert_equal "included", Redwright::LLM::ContextPolicy.layer_behavior(layer: "tree_sitter", family: "implementation")
    assert_equal "included", Redwright::LLM::ContextPolicy.layer_behavior(layer: "llm_based", family: "diagnosis")
    assert_equal "included", Redwright::LLM::ContextPolicy.layer_behavior(layer: "quizzes", family: "planning")
    assert_equal "included", Redwright::LLM::ContextPolicy.layer_behavior(layer: "dumps", family: "documentation")
    assert_equal "omitted", Redwright::LLM::ContextPolicy.layer_behavior(layer: "quizzes", family: "implementation")
    assert_equal "omitted", Redwright::LLM::ContextPolicy.layer_behavior(layer: "tree_sitter", family: "planning")
    assert_equal "included", Redwright::LLM::ContextPolicy.layer_behavior(
      layer: "dumps",
      family: Redwright::LLM::ContextPolicy::FULL_CONTEXT_FALLBACK
    )
  end

  test "full context fallback is an explicit registry policy" do
    policy = Redwright::LLM::ContextPolicy.fallback_policy

    assert_equal "full_context_fallback", policy.name
    assert_nil policy.work_family
    assert_equal Redwright::LLM::ContextPolicy::ALL_CONTEXT_LAYERS, policy.included_layers
    assert policy.fallback?
  end

  test "maps agent ticket execution to implementation policy" do
    assert_equal "implementation", Redwright::LLM::ContextPolicy.family_for_action("agent_ticket_execution")
    assert_equal "implementation_default", Redwright::LLM::ContextPolicy.policy_name_for_action("agent_ticket_execution")
  end

  test "maps quiz generation actions to exploration policy" do
    assert_equal "exploration", Redwright::LLM::ContextPolicy.family_for_action("quiz_question_generation")
    assert_equal "exploration_default", Redwright::LLM::ContextPolicy.policy_name_for_action("quiz_question_generation")
    assert_equal "exploration", Redwright::LLM::ContextPolicy.family_for_action("quiz_fast_question_generation")
    assert_equal "exploration_default", Redwright::LLM::ContextPolicy.policy_name_for_action("quiz_fast_question_generation")
  end

  test "maps project setup prompt rendering to planning policy" do
    assert_equal "planning", Redwright::LLM::ContextPolicy.family_for_action("project_setup_prompt_render")
    assert_equal "planning_default", Redwright::LLM::ContextPolicy.policy_name_for_action("project_setup_prompt_render")
  end

  test "maps legacy Telegram runtime interpretation actions" do
    assert_equal "planning", Redwright::LLM::ContextPolicy.family_for_action("intent_interpret")
    assert_equal "planning", Redwright::LLM::ContextPolicy.family_for_action("intent_interpret_with_current_context")
    assert_equal "planning", Redwright::LLM::ContextPolicy.family_for_action("intent_interpret_with_gap_answer")
    assert_equal "diagnosis", Redwright::LLM::ContextPolicy.family_for_action("intent_refine_with_errors")
  end

  test "maps direct legacy LLM actions" do
    assert_equal "planning_default", Redwright::LLM::ContextPolicy.policy_name_for_action("alignment_question_generation")
    assert_equal "operation_default", Redwright::LLM::ContextPolicy.policy_name_for_action("runtime_container_generation")
  end

  test "unmapped actions are explicit nil mappings" do
    assert_nil Redwright::LLM::ContextPolicy.family_for_action("unknown_action")
    assert_nil Redwright::LLM::ContextPolicy.policy_name_for_action("unknown_action")
  end
end
