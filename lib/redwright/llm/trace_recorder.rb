# frozen_string_literal: true

require_relative "../trace"

module Redwright
  module LLM
    class TraceRecorder
      def initialize(trace: Trace)
        @trace = trace
      end

      def record_request(
        model_role:,
        provider:,
        model:,
        action:,
        payload_bytes:,
        llm_call_id: nil,
        trace_id: nil,
        model_alias: nil,
        resolved_model: nil,
        system_prompt: nil,
        user_text: nil,
        project_id: nil,
        project_ref: nil,
        project_root: nil,
        ticket_id: nil,
        session_id: nil,
        source_channel: nil,
        actor_identifier: nil,
        context_summary: nil,
        context_bytes: nil,
        context_sections: nil,
        policy_decision: nil
      )
        @trace.llm_request(
          role: model_role,
          provider: provider,
          model: model,
          action: action,
          payload_bytes: payload_bytes,
          llm_call_id: llm_call_id,
          trace_id: trace_id,
          model_alias: model_alias,
          resolved_model: resolved_model,
          system_prompt: system_prompt,
          user_text: user_text,
          project_id: project_id,
          project_ref: project_ref,
          project_root: project_root,
          ticket_id: ticket_id,
          session_id: session_id,
          source_channel: source_channel,
          actor_identifier: actor_identifier,
          context_summary: context_summary,
          context_bytes: context_bytes,
          context_sections: context_sections,
          policy_decision: policy_decision
        )
      end

      def record_response(
        status:,
        latency_ms:,
        output_bytes:,
        llm_call_id: nil,
        trace_id: nil,
        finish_reason: nil,
        raw_output: nil,
        parsed_intent: nil,
        parsed_message: nil,
        parsed_fields: nil,
        decision_source: nil,
        error: nil,
        project_id: nil,
        project_ref: nil,
        project_root: nil,
        ticket_id: nil,
        session_id: nil,
        source_channel: nil,
        actor_identifier: nil,
        action: nil,
        model_role: nil,
        provider: nil,
        model: nil,
        model_alias: nil,
        resolved_model: nil,
        payload_bytes: nil,
        warnings: nil,
        diagnostics: nil,
        policy_decision: nil
      )
        @trace.llm_response(
          status: status,
          latency_ms: latency_ms,
          output_bytes: output_bytes,
          llm_call_id: llm_call_id,
          trace_id: trace_id,
          finish_reason: finish_reason,
          raw_output: raw_output,
          parsed_intent: parsed_intent,
          parsed_message: parsed_message,
          parsed_fields: parsed_fields,
          decision_source: decision_source,
          error: error,
          project_id: project_id,
          project_ref: project_ref,
          project_root: project_root,
          ticket_id: ticket_id,
          session_id: session_id,
          source_channel: source_channel,
          actor_identifier: actor_identifier,
          action: action,
          role: model_role,
          provider: provider,
          model: model,
          model_alias: model_alias,
          resolved_model: resolved_model,
          payload_bytes: payload_bytes,
          warnings: warnings,
          diagnostics: diagnostics,
          policy_decision: policy_decision
        )
      end
    end
  end
end
