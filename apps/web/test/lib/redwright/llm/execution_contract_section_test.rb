# frozen_string_literal: true

require "test_helper"
require File.expand_path("../../../../../../lib/redwright/llm/execution_contract_section", __dir__)
require File.expand_path("../../../../../../lib/redwright/llm/execution_profile", __dir__)

class RedwrightLLMExecutionContractSectionTest < ActiveSupport::TestCase
  test "builds a high-authority execution contract context section" do
    section = Redwright::LLM::ExecutionContractSection.build(
      content: {
        primary_work_family: "implementation",
        context_policy: "implementation_default"
      }
    )

    assert_equal "execution_contract", section.name
    assert_equal "execution_contract", section.authority
    assert_equal true, section.metadata.fetch(:high_authority)
    assert_equal "implementation", section.content.fetch(:primary_work_family)
  end

  test "includes variable execution constraints" do
    profile = Redwright::LLM::ExecutionProfile.from_hash(
      primary_work_family: "implementation",
      confidence: "high",
      requires_code_changes: true,
      requires_command_execution: true,
      requires_validation: true,
      should_ask_clarification: false,
      reasoning_summary: "Implement the ticket."
    )
    workspace_boundary = Struct.new(:context).new(
      {
        "workspace_path" => "/workspace/app",
        "branch_name" => "agent-ticket-1",
        "project_id" => 10,
        "ticket_id" => 20
      }
    )

    section = Redwright::LLM::ExecutionContractSection.build(
      execution_profile: profile,
      execution_mode: "targeted",
      allowed_outputs: %i[files commands],
      allowed_actions: %w[write_file run],
      validation_required: true,
      retry_attempt: 2,
      max_attempts: 3,
      workspace_boundary: workspace_boundary
    )

    assert_equal "implementation", section.content.fetch(:primary_work_family)
    assert_equal "implementation_default", section.content.fetch(:context_policy)
    assert_equal "targeted", section.content.fetch(:execution_mode)
    assert_equal %w[files commands], section.content.fetch(:allowed_outputs)
    assert_equal %w[write_file run], section.content.fetch(:allowed_actions)
    assert_equal true, section.content.fetch(:validation_required)
    assert_equal 2, section.content.fetch(:retry_attempt)
    assert_equal 3, section.content.fetch(:max_attempts)
    assert_equal "/workspace/app", section.content.fetch(:workspace_boundary).fetch("workspace_path")
  end

  test "keeps stable agent instructions out of the execution contract" do
    section = Redwright::LLM::ExecutionContractSection.build(
      content: {
        primary_work_family: "planning",
        system_prompt: "You are a stable agent instruction.",
        agent_instructions: "Keep this in the system prompt.",
        stable_agent_instructions: "Do not inject this as context.",
        agent: "Do not create a broad agent context section."
      }
    )

    assert_equal "execution_contract", section.name
    assert_equal "planning", section.content.fetch(:primary_work_family)
    refute section.content.key?(:system_prompt)
    refute section.content.key?(:agent_instructions)
    refute section.content.key?(:stable_agent_instructions)
    refute section.content.key?(:agent)
  end
end
