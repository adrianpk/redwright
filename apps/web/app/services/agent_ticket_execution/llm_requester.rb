require Rails.root.join("..", "..", "lib", "redwright", "llm", "request_engine").expand_path.to_s

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
      provider_user_text = provider_user_text(user_text: user_text, context_sections: context_sections)
      llm_call_id = record_request(user_text: provider_user_text, context_sections: context_sections, trace_metadata: trace_metadata)
      response = request_engine.generate_structured_message(
        model: model,
        model_role: LlmContract::MODEL_ROLE,
        provider: provider,
        action: LlmContract::ACTION,
        system_prompt: LlmContract.system_prompt,
        user_text: provider_user_text,
        output_contract: LlmContract.output_contract,
        context_sections: context_sections,
        trace_metadata: trace_metadata
      )
      contract_result = response.ok? ? contract.validate(response.semantic_payload) : nil
      record_response(response: response, llm_call_id: llm_call_id, trace_metadata: trace_metadata)
      Result.new(ok: response.ok? && contract_result&.ok?, response: response, contract_result: contract_result)
    end

    private

    attr_reader :request_engine, :contract, :model, :provider, :trace_recorder

    def provider_user_text(user_text:, context_sections:)
      JSON.generate(
        "request" => JSON.parse(user_text),
        "context_sections" => context_sections.map { |section| provider_context_section(section) }
      )
    rescue JSON::ParserError
      JSON.generate(
        "request" => user_text.to_s,
        "context_sections" => context_sections.map { |section| provider_context_section(section) }
      )
    end

    def provider_context_section(section)
      section.to_h.merge("content" => section.content)
    end

    def record_request(user_text:, context_sections:, trace_metadata:)
      return nil unless trace_recorder

      trace_recorder.record_request(
        model_role: LlmContract::MODEL_ROLE,
        provider: provider,
        model: model,
        action: LlmContract::ACTION,
        payload_bytes: user_text.bytesize,
        system_prompt: LlmContract.system_prompt,
        user_text: user_text,
        project_id: trace_metadata[:project_id],
        project_ref: trace_metadata[:project_ref],
        project_root: trace_metadata[:project_root],
        ticket_id: trace_metadata[:ticket_id],
        context_summary: trace_metadata[:context_summary],
        context_bytes: trace_metadata[:context_bytes],
        context_sections: context_sections.map(&:to_h)
      )
    end

    def record_response(response:, llm_call_id:, trace_metadata:)
      return nil unless trace_recorder

      trace_recorder.record_response(
        status: response.status,
        latency_ms: 0,
        output_bytes: response.raw_response_ref.to_s.bytesize,
        llm_call_id: llm_call_id,
        finish_reason: response.provider_metadata[:finish_reason],
        raw_output: response.raw_response_ref,
        parsed_fields: response.semantic_payload.keys,
        project_id: trace_metadata[:project_id],
        project_ref: trace_metadata[:project_ref],
        project_root: trace_metadata[:project_root],
        ticket_id: trace_metadata[:ticket_id],
        action: LlmContract::ACTION,
        model_role: LlmContract::MODEL_ROLE,
        provider: provider,
        model: model,
        payload_bytes: response.diagnostics[:context_bytes]
      )
    end
  end
end
