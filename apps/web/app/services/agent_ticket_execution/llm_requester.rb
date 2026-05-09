require Rails.root.join("..", "..", "lib", "redwright", "llm", "request_engine").expand_path.to_s
require Rails.root.join("..", "..", "lib", "redwright", "llm", "context_policy").expand_path.to_s

module AgentTicketExecution
  class LlmRequester
    Result = Struct.new(:ok, :response, :contract_result, keyword_init: true) do
      def ok?
        ok == true
      end

      def payload
        contract_result&.payload || {}
      end

      def status
        response&.status
      end

      def warnings
        messages = Array(response&.warnings)
        messages << contract_result.message if contract_result && !contract_result.ok?
        messages
      end
    end

    def initialize(request_engine:, contract: LlmContract.new, model:, provider:, trace_recorder: nil)
      @request_engine = request_engine
      @contract = contract
      @model = model
      @provider = provider
      @trace_recorder = trace_recorder
    end

    def call(execution_context:)
      inputs = execution_context.llm_request_inputs
      user_text = inputs.fetch(:user_text)
      context_sections = inputs.fetch(:context_sections)
      trace_metadata = inputs.fetch(:trace_metadata)
      context_policy = context_policy_name
      provider_user_text = provider_user_text(user_text: user_text, context_sections: context_sections)
      llm_call_id = record_request(user_text: provider_user_text, context_sections: context_sections, trace_metadata: trace_metadata, context_policy: context_policy)
      response = request_engine.generate_structured_message(
        model: model,
        model_role: LlmContract::MODEL_ROLE,
        provider: provider,
        action: LlmContract::ACTION,
        system_prompt: LlmContract.system_prompt,
        user_text: provider_user_text,
        output_contract: LlmContract.output_contract,
        context_sections: context_sections,
        context_policy: context_policy,
        dynamic_context_policy: true,
        trace_metadata: trace_metadata
      )
      contract_result = response.ok? ? contract.validate(response.semantic_payload) : nil
      record_response(response: response, contract_result: contract_result, llm_call_id: llm_call_id, trace_metadata: trace_metadata)
      Result.new(ok: response.ok? && contract_result&.ok?, response: response, contract_result: contract_result)
    end

    private

    attr_reader :request_engine, :contract, :model, :provider, :trace_recorder

    def context_policy_name
      Redwright::LLM::ContextPolicy.policy_name_for_action(LlmContract::ACTION)
    end

    def policy_decision_for_trace(context_policy)
      policy = Redwright::LLM::ContextPolicy.fetch_policy(context_policy)
      return nil unless policy

      {
        policy_name: policy.name,
        work_family: policy.work_family,
        fallback: policy.fallback?,
        included_layers: policy.included_layers
      }
    end

    def provider_user_text(user_text:, context_sections:)
      section_names = context_sections.map { |section| section.name.to_s }
      JSON.generate(
        "request" => JSON.parse(user_text),
        "context_sections" => context_sections.map { |section| provider_context_section(section, section_names: section_names) }
      )
    rescue JSON::ParserError
      JSON.generate(
        "request" => user_text.to_s,
        "context_sections" => context_sections.map { |section| provider_context_section(section, section_names: section_names) }
      )
    end

    def provider_context_section(section, section_names:)
      payload = section.to_h
      if section.name.to_s == "protocol_model" && section_names.include?("protocol_files")
        payload.merge(
          "content_omitted" => true,
          "omission_reason" => "duplicated_by_protocol_files"
        )
      else
        payload.merge("content" => section.content)
      end
    end

    def record_request(user_text:, context_sections:, trace_metadata:, context_policy:)
      return nil unless trace_recorder

      trace_recorder.record_request(
        model_role: LlmContract::MODEL_ROLE,
        provider: provider,
        model: model,
        action: LlmContract::ACTION,
        payload_bytes: user_text.bytesize,
        trace_id: trace_metadata[:trace_id],
        system_prompt: LlmContract.system_prompt,
        user_text: user_text,
        project_id: trace_metadata[:project_id],
        project_ref: trace_metadata[:project_ref],
        project_root: trace_metadata[:project_root],
        ticket_id: trace_metadata[:ticket_id],
        session_id: trace_metadata[:session_id],
        source_channel: trace_metadata[:source_channel],
        actor_identifier: trace_metadata[:actor_identifier],
        context_summary: trace_metadata[:context_summary],
        context_bytes: trace_metadata[:context_bytes],
        context_sections: context_sections.map(&:to_h),
        policy_decision: policy_decision_for_trace(context_policy)
      )
    end

    def record_response(response:, contract_result:, llm_call_id:, trace_metadata:)
      return nil unless trace_recorder

      diagnostics = response.diagnostics.dup
      diagnostics[:contract_normalizations] = contract_result.normalizations if contract_result&.normalizations&.any?
      diagnostics[:contract_validation] = {
        code: contract_result.code,
        message: contract_result.message,
        ok: contract_result.ok?
      } if contract_result

      trace_recorder.record_response(
        status: response.status,
        latency_ms: 0,
        output_bytes: response.raw_response_ref.to_s.bytesize,
        llm_call_id: llm_call_id,
        trace_id: trace_metadata[:trace_id],
        finish_reason: response.provider_metadata[:finish_reason],
        raw_output: response.raw_response_ref,
        parsed_fields: response.semantic_payload.keys,
        project_id: trace_metadata[:project_id],
        project_ref: trace_metadata[:project_ref],
        project_root: trace_metadata[:project_root],
        ticket_id: trace_metadata[:ticket_id],
        session_id: trace_metadata[:session_id],
        source_channel: trace_metadata[:source_channel],
        actor_identifier: trace_metadata[:actor_identifier],
        action: LlmContract::ACTION,
        model_role: LlmContract::MODEL_ROLE,
        provider: provider,
        model: model,
        payload_bytes: response.diagnostics[:context_bytes],
        warnings: response.warnings,
        diagnostics: diagnostics,
        policy_decision: response.diagnostics[:context_policy]
      )
    end
  end
end
