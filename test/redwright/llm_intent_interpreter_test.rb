# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/llm_intent_interpreter"

class LlmIntentInterpreterTest < Minitest::Test
  Completion = Struct.new(:content, :finish_reason, keyword_init: true)

  class FakeLlmClient
    def initialize(configured: true, completion: nil, raises: nil)
      @configured = configured
      @completion = completion
      @raises = raises
    end

    def configured?
      @configured
    end

    def complete_json(model:, system_prompt:, user_text:)
      raise @raises if @raises

      raise "missing completion" unless @completion
      raise "missing model" if model.to_s.empty?
      raise "missing prompt" if system_prompt.to_s.empty?
      raise "missing user text" if user_text.to_s.empty?

      @completion
    end
  end

  def test_returns_fallback_when_client_not_configured
    interpreter = Redwright::LlmIntentInterpreter.new(
      llm_client: FakeLlmClient.new(configured: false)
    )

    decision = interpreter.interpret(text: "hola", model: "gpt-5-mini")
    assert_equal("fallback", decision.source)
    assert_equal("change", decision.intent)
    assert_equal("hola", decision.message)
    assert_equal("llm_not_configured", decision.finish_reason)
  end

  def test_returns_llm_decision_when_payload_is_valid
    interpreter = Redwright::LlmIntentInterpreter.new(
      llm_client: FakeLlmClient.new(
        completion: Completion.new(
          content: "{\"intent\":\"meta\",\"message\":\"show runtime status\"}",
          finish_reason: "stop"
        )
      )
    )

    decision = interpreter.interpret(text: "estado", model: "gpt-5-mini")
    assert_equal("llm", decision.source)
    assert_equal("meta", decision.intent)
    assert_equal("show runtime status", decision.message)
    assert_equal("stop", decision.finish_reason)
  end

  def test_returns_fallback_on_invalid_payload
    interpreter = Redwright::LlmIntentInterpreter.new(
      llm_client: FakeLlmClient.new(
        completion: Completion.new(content: "{\"intent\":\"weird\"}", finish_reason: "stop")
      )
    )

    decision = interpreter.interpret(text: "foo", model: "gpt-5-mini")
    assert_equal("fallback", decision.source)
    assert_equal("change", decision.intent)
    assert_equal("foo", decision.message)
    assert_equal("invalid_intent", decision.finish_reason)
  end
end
