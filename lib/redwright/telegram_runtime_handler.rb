# frozen_string_literal: true

require_relative "trace"

module Redwright
  class TelegramRuntimeHandler
    def initialize(flow:, telegram_client:, out:, err:, blocked_retry_attempts:, default_intent: "change")
      @flow = flow
      @telegram_client = telegram_client
      @out = out
      @err = err
      @blocked_retry_attempts = blocked_retry_attempts
      @default_intent = default_intent
    end

    def handle(event)
      Trace.banner("INGRESS TRACE", {
        trace_id: Trace.current_trace_id || "none",
        transport: "telegram",
        chat_id: event.chat_id,
        text: event.text
      })
      Trace.llm_request(
        role: "non_coding",
        provider: "none",
        model: "none",
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

      text = +"ok\n"
      text << "project_id: #{result.project.id}\n"
      text << "workstream_id: #{result.workstream.id}\n"
      text << "task_id: #{result.task.id}\n"
      text << "state: #{result.workstream.state}"
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
      @telegram_client.send_message(chat_id: event.chat_id, text: "error: #{e.message}")
      @err.puts("telegram processing error chat=#{event.chat_id}: #{e.message}")
    end
  end
end
