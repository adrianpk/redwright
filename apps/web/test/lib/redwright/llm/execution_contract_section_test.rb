# frozen_string_literal: true

require "test_helper"
require File.expand_path("../../../../../../lib/redwright/llm/execution_contract_section", __dir__)

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
end
