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
end
