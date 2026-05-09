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
      refute policy.fallback?
    end
  end
end
