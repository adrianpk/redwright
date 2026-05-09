# frozen_string_literal: true

require "json"

require_relative "context_policy"
require_relative "execution_profile"
require_relative "redactor"

module Redwright
  module LLM
    class ContextPreclassifier
      SYSTEM_PROMPT = <<~PROMPT.freeze
        You classify a software engineering request for context policy selection.
        Return only JSON matching the requested execution profile contract.
        Choose one strongest primary_work_family.
        Do not rewrite the downstream prompt or decide the business workflow.
      PROMPT

      OUTPUT_CONTRACT = {
        "required_fields" => ExecutionProfile::REQUIRED_FIELDS.map(&:to_s),
        "rendered_text_field" => "reasoning_summary"
      }.freeze

      Result = Struct.new(:status, :profile, :warnings, :raw_response_ref, :diagnostics, keyword_init: true) do
        def ok?
          status == "ok"
        end
      end

      def initialize(llm_client:, model:)
        @llm_client = llm_client
        @model = model
      end

      def classify(action:, model_role:, user_text:, trace_metadata: {})
        return fallback_result(action: action, reason: "llm_unavailable", raw_response_ref: nil) unless llm_configured?

        downstream_prompt = user_text.to_s
        completion = llm_client.complete_json(
          model: model,
          system_prompt: SYSTEM_PROMPT,
          user_text: classifier_payload(action: action, model_role: model_role, user_text: downstream_prompt, trace_metadata: trace_metadata)
        )
        profile_from_completion(completion: completion, action: action)
      rescue JSON::ParserError
        fallback_result(action: action, reason: "invalid_json", raw_response_ref: nil)
      rescue StandardError => e
        fallback_result(action: action, reason: "provider_error", raw_response_ref: e.message)
      end

      private

      attr_reader :llm_client, :model

      def llm_configured?
        llm_client&.configured?
      end

      def classifier_payload(action:, model_role:, user_text:, trace_metadata:)
        JSON.generate(
          {
            action: action.to_s,
            model_role: model_role.to_s,
            request_text: Redactor.redact_text(user_text),
            allowed_work_families: ContextPolicy::WORK_FAMILIES,
            allowed_confidence_bands: ContextPolicy::CONFIDENCE_BANDS,
            output_contract: OUTPUT_CONTRACT,
            trace_metadata: trace_metadata || {}
          }
        )
      end

      def profile_from_completion(completion:, action:)
        raw_content = completion.content.to_s
        return fallback_result(action: action, reason: "empty_response", raw_response_ref: raw_content) if raw_content.strip.empty?

        parsed = JSON.parse(raw_content)
        return fallback_result(action: action, reason: "non_object_response", raw_response_ref: raw_content) unless parsed.is_a?(Hash)

        profile = ExecutionProfile.from_hash(parsed)
        return fallback_result(action: action, reason: profile.errors.join("; "), raw_response_ref: raw_content) unless profile.valid?

        Result.new(
          status: "ok",
          profile: profile,
          warnings: [],
          raw_response_ref: raw_content,
          diagnostics: {
            source: "llm_preclassifier",
            action: action.to_s,
            context_policy: profile.context_policy,
            primary_work_family: profile.primary_work_family,
            confidence: profile.confidence
          }
        )
      rescue JSON::ParserError
        fallback_result(action: action, reason: "invalid_json", raw_response_ref: raw_content)
      end

      def fallback_result(action:, reason:, raw_response_ref:)
        Result.new(
          status: "fallback",
          profile: fallback_profile(action: action, reason: reason),
          warnings: [reason.to_s],
          raw_response_ref: raw_response_ref,
          diagnostics: {
            source: "llm_preclassifier_fallback",
            action: action.to_s,
            fallback_reason: reason.to_s
          }
        )
      end

      def fallback_profile(action:, reason:)
        family = ContextPolicy.family_for_action(action) || "exploration"
        ExecutionProfile.from_hash(
          primary_work_family: family,
          confidence: "low",
          requires_code_changes: false,
          requires_command_execution: false,
          requires_validation: false,
          should_ask_clarification: false,
          reasoning_summary: "Context preclassification fallback: #{reason}"
        )
      end
    end
  end
end
