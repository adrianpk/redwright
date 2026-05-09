# frozen_string_literal: true

require "json"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/llm/context_preclassifier"

class LlmContextPreclassifierTest < Minitest::Test
  Completion = Struct.new(:content, :finish_reason, keyword_init: true)

  class FakeClient
    attr_reader :calls

    def initialize(content:, configured: true)
      @content = content
      @configured = configured
      @calls = []
    end

    def configured?
      @configured
    end

    def complete_json(model:, system_prompt:, user_text:)
      @calls << {model: model, system_prompt: system_prompt, user_text: JSON.parse(user_text)}
      Completion.new(content: @content, finish_reason: "stop")
    end
  end

  def test_returns_valid_execution_profile
    client = FakeClient.new(content: profile_payload(family: "implementation", confidence: "high"))
    preclassifier = Redwright::LLM::ContextPreclassifier.new(llm_client: client, model: "test/model")

    result = preclassifier.classify(
      action: "agent_ticket_execution",
      model_role: "coding",
      user_text: "Implement the ticket."
    )

    assert_predicate result, :ok?
    assert_equal "implementation", result.profile.primary_work_family
    assert_equal "implementation_default", result.profile.context_policy
    assert_equal "high", result.profile.confidence
  end

  def test_invalid_response_falls_back_to_full_context_policy
    client = FakeClient.new(content: JSON.generate({"primary_work_family" => "mixed"}))
    preclassifier = Redwright::LLM::ContextPreclassifier.new(llm_client: client, model: "test/model")

    result = preclassifier.classify(
      action: "agent_ticket_execution",
      model_role: "coding",
      user_text: "Implement the ticket."
    )

    refute_predicate result, :ok?
    assert_equal "implementation", result.profile.primary_work_family
    assert_equal "full_context_fallback", result.profile.context_policy
    assert_equal "low", result.profile.confidence
  end

  def test_returns_valid_profiles_for_all_work_families
    Redwright::LLM::ContextPolicy::WORK_FAMILIES.each do |family|
      client = FakeClient.new(content: profile_payload(family: family, confidence: "medium"))
      preclassifier = Redwright::LLM::ContextPreclassifier.new(llm_client: client, model: "test/model")

      result = preclassifier.classify(
        action: "#{family}_action",
        model_role: "non_coding",
        user_text: "Classify this #{family} request."
      )

      assert_predicate result, :ok?
      assert_equal family, result.profile.primary_work_family
      assert_equal "#{family}_default", result.profile.context_policy
      assert_equal "medium", result.profile.confidence
    end
  end

  def test_low_confidence_response_selects_full_context_fallback
    client = FakeClient.new(content: profile_payload(family: "planning", confidence: "low"))
    preclassifier = Redwright::LLM::ContextPreclassifier.new(llm_client: client, model: "test/model")

    result = preclassifier.classify(
      action: "project_setup_prompt_render",
      model_role: "non_coding",
      user_text: "Plan the next setup question."
    )

    assert_predicate result, :ok?
    assert_equal "planning", result.profile.primary_work_family
    assert_equal "full_context_fallback", result.profile.context_policy
    assert_equal "low", result.profile.confidence
  end

  private

  def profile_payload(family:, confidence:)
    JSON.generate(
      {
        "primary_work_family" => family,
        "confidence" => confidence,
        "requires_code_changes" => true,
        "requires_command_execution" => true,
        "requires_validation" => true,
        "should_ask_clarification" => false,
        "reasoning_summary" => "The request maps to #{family}."
      }
    )
  end
end
