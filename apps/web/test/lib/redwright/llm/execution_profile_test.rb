# frozen_string_literal: true

require "test_helper"
require File.expand_path("../../../../../../lib/redwright/llm/execution_profile", __dir__)

class RedwrightLLMExecutionProfileTest < ActiveSupport::TestCase
  test "normalizes a profile payload" do
    profile = Redwright::LLM::ExecutionProfile.from_hash(
      "primary_work_family" => "implementation",
      "confidence" => "high",
      "requires_code_changes" => true,
      "requires_command_execution" => true,
      "requires_validation" => true,
      "should_ask_clarification" => false,
      "reasoning_summary" => "Implement the requested ticket.",
      "expected_outputs" => ["patch", "tests"]
    )

    assert_equal "implementation", profile.primary_work_family
    assert_equal "implementation_default", profile.context_policy
    assert_equal "high", profile.confidence
    assert_equal ["patch", "tests"], profile.expected_outputs
    assert_equal [], profile.runner_up_families
  end

  test "serializes profile data" do
    profile = Redwright::LLM::ExecutionProfile.from_hash(
      primary_work_family: :documentation,
      confidence: :medium,
      requires_code_changes: false,
      requires_command_execution: false,
      requires_validation: true,
      should_ask_clarification: false,
      reasoning_summary: "Update repository documentation."
    )

    assert_equal(
      {
        primary_work_family: "documentation",
        context_policy: "documentation_default",
        confidence: "medium",
        requires_code_changes: false,
        requires_command_execution: false,
        requires_validation: true,
        should_ask_clarification: false,
        reasoning_summary: "Update repository documentation.",
        runner_up_families: [],
        request_complexity: nil,
        expected_outputs: [],
        policy_inputs: {}
      },
      profile.to_h
    )
  end
end
