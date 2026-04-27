# frozen_string_literal: true

require_relative "planner_contract"
require_relative "planner_payload_validator"

module Redwright
  class LlmIntentInterpreter
    Decision = Struct.new(:intent, :message, :source, :finish_reason, :raw_output, keyword_init: true)

    SYSTEM_PROMPT = PlannerContract::SYSTEM_PROMPT

    def initialize(llm_client:, validator: PlannerPayloadValidator.new, max_validation_attempts: 2)
      @llm_client = llm_client
      @validator = validator
      @max_validation_attempts = max_validation_attempts
    end

    def interpret(text:, model:)
      return fallback(text, "llm_not_configured") unless @llm_client&.configured?

      last_raw_output = nil
      last_error = "invalid_payload"

      @max_validation_attempts.times do
        completion = @llm_client.complete_json(
          model: model,
          system_prompt: SYSTEM_PROMPT,
          user_text: text
        )
        last_raw_output = completion.content
        validation = @validator.validate(completion.content)
        unless validation.valid
          last_error = "invalid_payload:#{validation.errors.join('|')}"
          next
        end

        return Decision.new(
          intent: validation.intent,
          message: validation.message,
          source: "llm",
          finish_reason: completion.finish_reason || "stop",
          raw_output: completion.content
        )
      end

      fallback(text, last_error, raw_output: last_raw_output)
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
