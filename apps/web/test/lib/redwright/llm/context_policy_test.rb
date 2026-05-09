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
end
