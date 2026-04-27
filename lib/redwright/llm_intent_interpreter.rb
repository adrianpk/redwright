# frozen_string_literal: true

require_relative "planner_contract"
require_relative "planner_payload_validator"
require_relative "skill_dispatcher"
require_relative "planner_prompt_builder"

module Redwright
  class LlmIntentInterpreter
    Decision = Struct.new(:intent, :message, :actions, :source, :finish_reason, :raw_output, keyword_init: true)

    SYSTEM_PROMPT = PlannerContract::SYSTEM_PROMPT

    def initialize(
      llm_client:,
      validator: PlannerPayloadValidator.new,
      max_validation_attempts: 2,
      skill_dispatcher: SkillDispatcher.new,
      prompt_builder: PlannerPromptBuilder.new,
      project_context_provider: nil,
      architecture_context_provider: nil
    )
      @llm_client = llm_client
      @validator = validator
      @max_validation_attempts = max_validation_attempts
      @skill_dispatcher = skill_dispatcher
      @prompt_builder = prompt_builder
      @project_context_provider = project_context_provider
      @architecture_context_provider = architecture_context_provider
    end

    def interpret(text:, model:)
      context = { model: model, stage: "planner" }
      plan_text = @skill_dispatcher.before_plan(text: text, context: context)
      system_prompt = build_system_prompt(text: plan_text, model: model)

      return fallback(plan_text, "llm_not_configured") unless @llm_client&.configured?

      last_raw_output = nil
      last_error = "invalid_payload"

      @max_validation_attempts.times do
        completion = @llm_client.complete_json(
          model: model,
          system_prompt: system_prompt,
          user_text: plan_text
        )
        last_raw_output = completion.content
        validation = @validator.validate(completion.content)
        unless validation.valid
          last_error = "invalid_payload:#{validation.errors.join('|')}"
          next
        end

        decision = Decision.new(
          intent: validation.intent,
          message: validation.message,
          actions: validation.actions,
          source: "llm",
          finish_reason: completion.finish_reason || "stop",
          raw_output: completion.content
        )
        return @skill_dispatcher.after_plan(decision: decision, context: context)
      end

      fallback(plan_text, last_error, raw_output: last_raw_output)
    rescue StandardError => e
      fallback(plan_text || text, "llm_error:#{e.class}")
    end

    def system_prompt
      @prompt_builder.build
    end

    private

    def build_system_prompt(text:, model:)
      @prompt_builder.build(
        project_context: resolve_context_provider(@project_context_provider, text: text, model: model),
        architecture_context: resolve_context_provider(@architecture_context_provider, text: text, model: model)
      )
    end

    def resolve_context_provider(provider, text:, model:)
      return nil unless provider.respond_to?(:call)

      provider.call(text: text, model: model, stage: "planner")
    rescue StandardError
      nil
    end

    def fallback(text, reason, raw_output: nil)
      Decision.new(
        intent: "change",
        message: text,
        actions: [],
        source: "fallback",
        finish_reason: reason,
        raw_output: raw_output
      )
    end
  end
end
