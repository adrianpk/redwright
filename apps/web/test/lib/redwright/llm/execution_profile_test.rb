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

  test "reports missing and invalid required fields" do
    profile = Redwright::LLM::ExecutionProfile.from_hash(
      primary_work_family: "mixed",
      confidence: "uncertain",
      requires_code_changes: nil,
      requires_command_execution: false,
      requires_validation: true,
      should_ask_clarification: false,
      reasoning_summary: ""
    )

    refute profile.valid?
    assert_includes profile.errors, "primary_work_family is invalid"
    assert_includes profile.errors, "confidence is invalid"
    assert_includes profile.errors, "context_policy is required"
    assert_includes profile.errors, "reasoning_summary is required"
    assert_includes profile.errors, "requires_code_changes must be true or false"
  end

  test "low confidence maps to full context fallback" do
    profile = Redwright::LLM::ExecutionProfile.from_hash(
      primary_work_family: "implementation",
      context_policy: "implementation_default",
      confidence: "low",
      requires_code_changes: true,
      requires_command_execution: true,
      requires_validation: true,
      should_ask_clarification: false,
      reasoning_summary: "The classifier is not confident enough."
    )

    assert profile.valid?
    assert_equal "full_context_fallback", profile.context_policy
  end
end
