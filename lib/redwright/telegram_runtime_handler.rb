# frozen_string_literal: true

require_relative "trace"
require_relative "runtime_result_envelope"
require_relative "llm_intent_interpreter"

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
      model_name: "none",
      intent_interpreter: nil
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
      @intent_interpreter = intent_interpreter
    end

    def handle(event)
      Trace.with_trace_id do
        begin
          Trace.banner("INGRESS TRACE", {
            trace_id: Trace.current_trace_id || "none",
            transport: "telegram",
            chat_id: event.chat_id,
            text: event.text
          })
          begin
            @telegram_client.send_chat_action(chat_id: event.chat_id, action: "typing")
          rescue StandardError => e
            @err.puts("telegram typing hint failed chat=#{event.chat_id}: #{e.message}")
          end
          Trace.llm_request(
            role: @model_role,
            provider: @model_provider,
            model: @model_name,
            action: "intent_interpret",
            payload_bytes: event.text.to_s.bytesize,
            system_prompt: LlmIntentInterpreter::SYSTEM_PROMPT.strip,
            user_text: event.text
          )
          started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          decision = interpreter.interpret(text: event.text, model: @model_name)
          elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).to_i
          Trace.llm_response(
            status: decision.source == "llm" ? "ok" : "fallback",
            latency_ms: elapsed_ms,
            output_bytes: decision.raw_output.to_s.bytesize,
            finish_reason: decision.finish_reason,
            decision_source: decision.source,
            parsed_intent: decision.intent,
            parsed_message: decision.message,
            raw_output: decision.raw_output
          )

          result = @flow.process(
            project_ref: nil,
            intent: decision.intent,
            message: decision.message,
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

    private

    def interpreter
      @intent_interpreter ||= LlmIntentInterpreter.new(llm_client: nil)
    end
  end
end
