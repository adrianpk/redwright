# frozen_string_literal: true

require "json"

require_relative "context_section"
require_relative "context_policy"
require_relative "redactor"

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
        context_policy: nil,
        execution_profile: nil,
        trace_metadata: {}
      )
        policy_decision = context_policy_decision(context_sections, context_policy: context_policy, execution_profile: execution_profile)
        selected_context_sections = policy_decision.fetch(:selected_context_sections)
        return failure_response("llm_unavailable", "LLM client is not configured", provider: provider, model: model, model_role: model_role, action: action, context_sections: selected_context_sections, trace_metadata: trace_metadata, policy_decision: policy_decision) unless llm_configured?

        safe_system_prompt = Redactor.redact_text(system_prompt)
        safe_user_text = Redactor.redact_text(user_text)
        completion = @llm_client.complete_json(
          model: model,
          system_prompt: safe_system_prompt,
          user_text: safe_user_text
        )
        normalize_completion(
          completion: completion,
          output_contract: output_contract,
          provider: provider,
          model: model,
          model_role: model_role,
          action: action,
          context_sections: selected_context_sections,
          trace_metadata: trace_metadata,
          policy_decision: policy_decision,
          redacted: safe_system_prompt != system_prompt.to_s || safe_user_text != user_text.to_s
        )
      rescue JSON::ParserError => e
        failure_response("invalid_response", "Provider response was not valid JSON", provider: provider, model: model, model_role: model_role, action: action, context_sections: selected_context_sections || context_sections, trace_metadata: trace_metadata, error: e, policy_decision: policy_decision)
      rescue StandardError => e
        failure_response("provider_error", "Provider request failed", provider: provider, model: model, model_role: model_role, action: action, context_sections: selected_context_sections || context_sections, trace_metadata: trace_metadata, error: e, policy_decision: policy_decision)
      end

      private

      def llm_configured?
        @llm_client&.configured?
      end

      def context_policy_decision(context_sections, context_policy:, execution_profile:)
        all_sections = Array(context_sections)
        policy_name = context_policy_name(context_policy: context_policy, execution_profile: execution_profile)
        return default_policy_decision(all_sections) unless policy_name

        policy = ContextPolicy.fetch_policy(policy_name)
        return default_policy_decision(all_sections).merge(policy_name: policy_name, unknown_policy: true) unless policy
        confidence = execution_profile.respond_to?(:confidence) ? execution_profile.confidence : nil
        return policy_decision_for(policy, all_sections, selected_sections: all_sections, omitted_sections: [], confidence: confidence) if policy.fallback?

        selected_sections = all_sections.select do |section|
          policy.included_layers.include?(context_layer_name(section))
        end
        omitted_sections = all_sections - selected_sections
        policy_decision_for(policy, all_sections, selected_sections: selected_sections, omitted_sections: omitted_sections, confidence: confidence)
      end

      def context_policy_name(context_policy:, execution_profile:)
        return execution_profile.context_policy if execution_profile&.respond_to?(:context_policy)
        return context_policy.name if context_policy&.respond_to?(:name)

        context_policy&.to_s
      end

      def default_policy_decision(context_sections)
        {
          selected_context_sections: context_sections,
          policy_name: nil,
          work_family: nil,
          confidence: nil,
          fallback: false,
          unknown_policy: false,
          included_layers: [],
          included_context_sections: context_section_names(context_sections),
          omitted_context_sections: [],
          omission_reasons: {}
        }
      end

      def policy_decision_for(policy, all_sections, selected_sections:, omitted_sections:, confidence:)
        {
          selected_context_sections: selected_sections,
          policy_name: policy.name,
          work_family: policy.work_family,
          confidence: confidence,
          fallback: policy.fallback?,
          unknown_policy: false,
          included_layers: policy.included_layers,
          included_context_sections: context_section_names(selected_sections),
          omitted_context_sections: context_section_names(omitted_sections),
          omission_reasons: omission_reasons(policy, omitted_sections)
        }
      end

      def omission_reasons(policy, omitted_sections)
        omitted_sections.each_with_object({}) do |section, reasons|
          name = section.respond_to?(:name) ? section.name.to_s : section.to_s
          reasons[name] = "context_layer_not_in_policy:#{context_layer_name(section)}:#{policy.name}"
        end
      end

      def context_layer_name(section)
        metadata = section.respond_to?(:metadata) ? section.metadata : nil
        layer = metadata[:context_layer] || metadata["context_layer"] if metadata.respond_to?(:[])
        return layer.to_s if layer

        section.respond_to?(:name) ? section.name.to_s : section.to_s
      end

      def normalize_completion(completion:, output_contract:, provider:, model:, model_role:, action:, context_sections:, trace_metadata:, policy_decision:, redacted: false)
        content = completion.content.to_s
        if content.strip.empty?
          return failure_response(
            "invalid_response",
            "Provider response was empty",
            provider: provider,
            model: model,
            model_role: model_role,
            action: action,
            context_sections: context_sections,
            trace_metadata: trace_metadata,
            raw_response_ref: completion.content,
            diagnostic_details: {response_failure: "empty_content"},
            redacted: redacted,
            policy_decision: policy_decision
          )
        end

        parsed = JSON.parse(content)
        unless parsed.is_a?(Hash)
          return invalid_shape_response(
            provider: provider,
            model: model,
            model_role: model_role,
            action: action,
            context_sections: context_sections,
            trace_metadata: trace_metadata,
            raw_response_ref: content,
            diagnostic_details: {response_failure: "non_object_json", parsed_class: parsed.class.name},
            redacted: redacted,
            policy_decision: policy_decision
          )
        end

        missing = required_fields(output_contract).reject { |field| parsed.key?(field) && !parsed[field].to_s.strip.empty? }
        unless missing.empty?
          return invalid_shape_response(
            provider: provider,
            model: model,
            model_role: model_role,
            action: action,
            context_sections: context_sections,
            trace_metadata: trace_metadata,
            missing_fields: missing,
            raw_response_ref: content,
            diagnostic_details: {response_failure: "missing_required_fields", missing_required_fields: missing},
            redacted: redacted,
            policy_decision: policy_decision
          )
        end

        rendered_text = parsed.fetch(rendered_text_field(output_contract)).to_s.strip
        Response.new(
          status: "ok",
          semantic_payload: parsed,
          rendered_text: rendered_text,
          provider_metadata: provider_metadata(provider: provider, model: model, model_role: model_role, action: action, finish_reason: completion.finish_reason),
          usage: nil,
          warnings: [],
          raw_response_ref: completion.content,
          diagnostics: diagnostics(context_sections: context_sections, trace_metadata: trace_metadata, policy_decision: policy_decision, redacted: redacted)
        )
      rescue JSON::ParserError => e
        failure_response("invalid_response", "Provider response was not valid JSON", provider: provider, model: model, model_role: model_role, action: action, context_sections: context_sections, trace_metadata: trace_metadata, error: e, raw_response_ref: content, diagnostic_details: {response_failure: "invalid_json"}, policy_decision: policy_decision, redacted: redacted)
      end

      def invalid_shape_response(provider:, model:, model_role:, action:, context_sections:, trace_metadata:, missing_fields: [], raw_response_ref: nil, diagnostic_details: {}, policy_decision:, redacted: false)
        message = missing_fields.empty? ? "Provider response did not match the output contract" : "Provider response missed required fields: #{missing_fields.join(', ')}"
        failure_response("invalid_response", message, provider: provider, model: model, model_role: model_role, action: action, context_sections: context_sections, trace_metadata: trace_metadata, raw_response_ref: raw_response_ref, diagnostic_details: diagnostic_details, policy_decision: policy_decision, redacted: redacted)
      end

      def failure_response(status, message, provider:, model:, model_role:, action:, context_sections:, trace_metadata:, error: nil, raw_response_ref: nil, diagnostic_details: {}, policy_decision: default_policy_decision(Array(context_sections)), redacted: false)
        Response.new(
          status: status,
          semantic_payload: {},
          rendered_text: "",
          provider_metadata: provider_metadata(provider: provider, model: model, model_role: model_role, action: action),
          usage: nil,
          warnings: [message],
          raw_response_ref: raw_response_ref || error&.message,
          diagnostics: diagnostics(context_sections: context_sections, trace_metadata: trace_metadata, error: error, policy_decision: policy_decision, redacted: redacted, details: diagnostic_details)
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

      def diagnostics(context_sections:, trace_metadata:, error: nil, policy_decision:, redacted: false, details: {})
        data = {
          context_sections: context_section_names(context_sections),
          context_section_authorities: context_section_authorities(context_sections),
          context_bytes: context_section_bytes(context_sections),
          trace_metadata: trace_metadata || {},
          context_policy: policy_diagnostics(policy_decision),
          redacted: redacted
        }
        data[:error_class] = error.class.name if error
        data[:error_message] = error.message if error
        details.each { |key, value| data[key.to_sym] = value } if details
        data
      end

      def policy_diagnostics(policy_decision)
        decision = policy_decision || default_policy_decision([])
        decision.reject { |key, _value| key == :selected_context_sections }
      end

      def context_section_names(context_sections)
        Array(context_sections).map { |section| section.respond_to?(:name) ? section.name.to_s : section.to_s }
      end

      def context_section_authorities(context_sections)
        Array(context_sections).each_with_object({}) do |section, authorities|
          next unless section.respond_to?(:name) && section.respond_to?(:authority)

          authorities[section.name.to_s] = section.authority.to_s
        end
      end

      def context_section_bytes(context_sections)
        Array(context_sections).sum do |section|
          section.respond_to?(:authority) && section.respond_to?(:bytes) ? section.bytes : section.to_s.bytesize
        end
      end
    end
  end
end
