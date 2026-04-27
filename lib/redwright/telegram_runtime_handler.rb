# frozen_string_literal: true

require_relative "trace"
require_relative "runtime_result_envelope"

module Redwright
  class TelegramRuntimeHandler
    def initialize(
      flow:,
      telegram_client:,
      out:,
      err:,
      blocked_retry_attempts:,
      default_intent: "change",
      model_role: "non_coding",
      model_provider: "none",
      model_name: "none"
    )
      @flow = flow
      @telegram_client = telegram_client
      @out = out
      @err = err
      @blocked_retry_attempts = blocked_retry_attempts
      @default_intent = default_intent
      @model_role = model_role
      @model_provider = model_provider
      @model_name = model_name
    end

    def handle(event)
      Trace.banner("INGRESS TRACE", {
        trace_id: Trace.current_trace_id || "none",
        transport: "telegram",
        chat_id: event.chat_id,
        text: event.text
      })
      Trace.llm_request(
        role: @model_role,
        provider: @model_provider,
        model: @model_name,
        action: "none",
        payload_bytes: 0
      )
      Trace.llm_response(status: "skipped", latency_ms: 0, output_bytes: 0, finish_reason: "llm_not_integrated")

      result = @flow.process(
        project_ref: nil,
        intent: @default_intent,
        message: event.text,
        confirm_new_workstream: true,
        blocked_retry_attempts: @blocked_retry_attempts
      )

      envelope = RuntimeResultEnvelope.success(
        trace_id: Trace.current_trace_id || "none",
        project_id: result.project.id,
        workstream_id: result.workstream.id,
        task_id: result.task.id,
        state: result.workstream.state
      )
      text = envelope.to_json_string
      @telegram_client.send_message(chat_id: event.chat_id, text: text)
      Trace.banner("RUNTIME TRACE", {
        trace_id: Trace.current_trace_id || "none",
        project_id: result.project.id,
        workstream_id: result.workstream.id,
        task_id: result.task.id,
        state: result.workstream.state
      })
      @out.puts("telegram processed chat=#{event.chat_id} task=#{result.task.id}")
    rescue StandardError => e
      error_envelope = RuntimeResultEnvelope.error(
        trace_id: Trace.current_trace_id || "none",
        message: e.message
      )
      @telegram_client.send_message(chat_id: event.chat_id, text: error_envelope.to_json_string)
      @err.puts("telegram processing error chat=#{event.chat_id}: #{e.message}")
    end
  end
end
