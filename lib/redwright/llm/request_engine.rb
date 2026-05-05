# frozen_string_literal: true

require "json"

module Redwright
  module LLM
    class RequestEngine
      Response = Struct.new(
        :status,
        :semantic_payload,
        :rendered_text,
        :provider_metadata,
        :usage,
        :warnings,
        :raw_response_ref,
        :diagnostics,
        keyword_init: true
      ) do
        def ok?
          status == "ok"
        end
      end

      DEFAULT_OUTPUT_CONTRACT = {
        "rendered_text_field" => "message",
        "required_fields" => ["message"]
      }.freeze

      def initialize(llm_client:)
        @llm_client = llm_client
      end

      def generate_structured_message(
        model:,
        model_role:,
        provider:,
        action:,
        system_prompt:,
        user_text:,
        output_contract: DEFAULT_OUTPUT_CONTRACT,
        context_sections: [],
        trace_metadata: {}
      )
        return failure_response("llm_unavailable", "LLM client is not configured", provider: provider, model: model, model_role: model_role, action: action, context_sections: context_sections, trace_metadata: trace_metadata) unless llm_configured?

        completion = @llm_client.complete_json(
          model: model,
          system_prompt: system_prompt,
          user_text: user_text
        )
        normalize_completion(
          completion: completion,
          output_contract: output_contract,
          provider: provider,
          model: model,
          model_role: model_role,
          action: action,
          context_sections: context_sections,
          trace_metadata: trace_metadata
        )
      rescue JSON::ParserError => e
        failure_response("invalid_response", "Provider response was not valid JSON", provider: provider, model: model, model_role: model_role, action: action, context_sections: context_sections, trace_metadata: trace_metadata, error: e)
      rescue StandardError => e
        failure_response("provider_error", "Provider request failed", provider: provider, model: model, model_role: model_role, action: action, context_sections: context_sections, trace_metadata: trace_metadata, error: e)
      end

      private

      def llm_configured?
        @llm_client&.configured?
      end

      def normalize_completion(completion:, output_contract:, provider:, model:, model_role:, action:, context_sections:, trace_metadata:)
        parsed = JSON.parse(completion.content.to_s)
        return invalid_shape_response(provider: provider, model: model, model_role: model_role, action: action, context_sections: context_sections, trace_metadata: trace_metadata) unless parsed.is_a?(Hash)

        missing = required_fields(output_contract).reject { |field| parsed.key?(field) && !parsed[field].to_s.strip.empty? }
        return invalid_shape_response(provider: provider, model: model, model_role: model_role, action: action, context_sections: context_sections, trace_metadata: trace_metadata, missing_fields: missing) unless missing.empty?

        rendered_text = parsed.fetch(rendered_text_field(output_contract)).to_s.strip
        Response.new(
          status: "ok",
          semantic_payload: parsed,
          rendered_text: rendered_text,
          provider_metadata: provider_metadata(provider: provider, model: model, model_role: model_role, action: action, finish_reason: completion.finish_reason),
          usage: nil,
          warnings: [],
          raw_response_ref: completion.content,
          diagnostics: diagnostics(context_sections: context_sections, trace_metadata: trace_metadata)
        )
      rescue JSON::ParserError => e
        failure_response("invalid_response", "Provider response was not valid JSON", provider: provider, model: model, model_role: model_role, action: action, context_sections: context_sections, trace_metadata: trace_metadata, error: e, raw_response_ref: completion.content)
      end

      def invalid_shape_response(provider:, model:, model_role:, action:, context_sections:, trace_metadata:, missing_fields: [])
        message = missing_fields.empty? ? "Provider response did not match the output contract" : "Provider response missed required fields: #{missing_fields.join(', ')}"
        failure_response("invalid_response", message, provider: provider, model: model, model_role: model_role, action: action, context_sections: context_sections, trace_metadata: trace_metadata)
      end

      def failure_response(status, message, provider:, model:, model_role:, action:, context_sections:, trace_metadata:, error: nil, raw_response_ref: nil)
        Response.new(
          status: status,
          semantic_payload: {},
          rendered_text: "",
          provider_metadata: provider_metadata(provider: provider, model: model, model_role: model_role, action: action),
          usage: nil,
          warnings: [message],
          raw_response_ref: raw_response_ref || error&.message,
          diagnostics: diagnostics(context_sections: context_sections, trace_metadata: trace_metadata, error: error)
        )
      end

      def required_fields(output_contract)
        contract = output_contract || DEFAULT_OUTPUT_CONTRACT
        Array(contract.fetch("required_fields", DEFAULT_OUTPUT_CONTRACT.fetch("required_fields"))).map(&:to_s)
      end

      def rendered_text_field(output_contract)
        contract = output_contract || DEFAULT_OUTPUT_CONTRACT
        contract.fetch("rendered_text_field", DEFAULT_OUTPUT_CONTRACT.fetch("rendered_text_field")).to_s
      end

      def provider_metadata(provider:, model:, model_role:, action:, finish_reason: nil)
        {
          provider: provider.to_s,
          model: model.to_s,
          model_role: model_role.to_s,
          action: action.to_s,
          finish_reason: finish_reason
        }.compact
      end

      def diagnostics(context_sections:, trace_metadata:, error: nil)
        data = {
          context_sections: Array(context_sections).map(&:to_s),
          trace_metadata: trace_metadata || {}
        }
        data[:error_class] = error.class.name if error
        data[:error_message] = error.message if error
        data
      end
    end
  end
end
