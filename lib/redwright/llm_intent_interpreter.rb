# frozen_string_literal: true

require "json"

module Redwright
  class LlmIntentInterpreter
    Decision = Struct.new(:intent, :message, :source, :finish_reason, :raw_output, keyword_init: true)

    SYSTEM_PROMPT = <<~PROMPT
      You route runtime tasks for a coding agent.
      Return strict JSON with:
      - intent: one of "change" or "meta"
      - message: concise normalized task text in English
      Do not return extra keys.
    PROMPT

    def initialize(llm_client:)
      @llm_client = llm_client
    end

    def interpret(text:, model:)
      return fallback(text, "llm_not_configured") unless @llm_client&.configured?

      completion = @llm_client.complete_json(
        model: model,
        system_prompt: SYSTEM_PROMPT,
        user_text: text
      )
      parsed = JSON.parse(completion.content)
      intent = parsed["intent"].to_s.strip
      message = parsed["message"].to_s.strip
      return fallback(text, "invalid_intent", raw_output: completion.content) unless %w[change meta].include?(intent)
      return fallback(text, "invalid_message", raw_output: completion.content) if message.empty?

      Decision.new(
        intent: intent,
        message: message,
        source: "llm",
        finish_reason: completion.finish_reason || "stop",
        raw_output: completion.content
      )
    rescue StandardError => e
      fallback(text, "llm_error:#{e.class}")
    end

    private

    def fallback(text, reason, raw_output: nil)
      Decision.new(
        intent: "change",
        message: text,
        source: "fallback",
        finish_reason: reason,
        raw_output: raw_output
      )
    end
  end
end
