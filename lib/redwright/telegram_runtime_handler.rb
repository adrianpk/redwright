# frozen_string_literal: true

require_relative "trace"
require_relative "runtime_result_envelope"
require_relative "llm_intent_interpreter"
require_relative "telegram_context_resolver"

module Redwright
  class TelegramRuntimeHandler
    def initialize(
      flow:,
      telegram_client:,
      out:,
      err:,
      context_resolver: nil,
      chat_context_store: nil,
      blocked_retry_attempts:,
      default_intent: "change",
      model_role: "non_coding",
      model_provider: "none",
      model_name: "none",
      intent_interpreter: nil,
      prompt_context_loader: nil,
      planner_rejection_store: nil,
      send_json_envelope: false,
      typing_interval_seconds: 4.0,
      typing_sleeper: ->(seconds) { sleep(seconds) }
    )
      @flow = flow
      @telegram_client = telegram_client
      @out = out
      @err = err
      @context_resolver = context_resolver
      @chat_context_store = chat_context_store
      @blocked_retry_attempts = blocked_retry_attempts
      @default_intent = default_intent
      @model_role = model_role
      @model_provider = model_provider
      @model_name = model_name
      @intent_interpreter = intent_interpreter
      @prompt_context_loader = prompt_context_loader
      @planner_rejection_store = planner_rejection_store
      @send_json_envelope = send_json_envelope
      @typing_interval_seconds = typing_interval_seconds
      @typing_sleeper = typing_sleeper
    end

    def handle(event)
      Trace.with_trace_id do
        stop_typing = nil
        begin
          Trace.banner("INGRESS TRACE", {
            trace_id: Trace.current_trace_id || "none",
            transport: "telegram",
            chat_id: event.chat_id,
            text: event.text
          })

          resolution = resolve_context(event: event)
          unless resolution.resolved
            clarify = RuntimeResultEnvelope.clarify(
              trace_id: Trace.current_trace_id || "none",
              message: resolution.question
            )
            @telegram_client.send_message(
              chat_id: event.chat_id,
              text: human_clarify_message(question: resolution.question, trace_id: Trace.current_trace_id || "none")
            )
            send_json_envelope_if_enabled(chat_id: event.chat_id, envelope: clarify)
            @out.puts("telegram clarify chat=#{event.chat_id}")
            return
          end

          prompt_context = load_prompt_context(project_path: resolution.project_path)
          stop_typing = start_typing_keepalive(event.chat_id)
          Trace.llm_request(
            role: @model_role,
            provider: @model_provider,
            model: @model_name,
            action: "intent_interpret",
            payload_bytes: event.text.to_s.bytesize,
            system_prompt: trace_system_prompt_for_interpreter(
              project_context: prompt_context[:project_context],
              architecture_context: prompt_context[:architecture_context]
            ),
            user_text: event.text
          )
          started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          decision = interpret_with_context(
            text: event.text,
            model: @model_name,
            project_context: prompt_context[:project_context],
            architecture_context: prompt_context[:architecture_context]
          )
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

          if decision.source == "fallback" && planner_decision_invalid?(decision)
            rejection = persist_planner_rejection(
              resolution: resolution,
              reason: decision.finish_reason,
              raw_output: decision.raw_output,
              user_text: event.text
            )
            Trace.runtime({
              trace_id: Trace.current_trace_id || "none",
              planner_rejection_id: rejection&.id || "none",
              planner_rejection_reason: decision.finish_reason
            })
            @telegram_client.send_message(
              chat_id: event.chat_id,
              text: human_planner_rejection_message(reason: decision.finish_reason, trace_id: Trace.current_trace_id || "none")
            )
            @out.puts("telegram planner_reject chat=#{event.chat_id}")
            return
          end

          result = @flow.process(
            project_ref: resolution.project_ref,
            intent: decision.intent,
            message: decision.message,
            actions: decision.respond_to?(:actions) ? decision.actions : [],
            workstream_id: resolution.workstream_id,
            confirm_new_workstream: true,
            blocked_retry_attempts: @blocked_retry_attempts
          )
          @chat_context_store&.upsert(
            chat_id: event.chat_id,
            project_id: result.project.id,
            workstream_id: result.workstream.id
          )

          envelope = RuntimeResultEnvelope.success(
            trace_id: Trace.current_trace_id || "none",
            project_id: result.project.id,
            workstream_id: result.workstream.id,
            task_id: result.task.id,
            state: result.workstream.state,
            execution: build_execution_summary(result)
          )
          @telegram_client.send_message(
            chat_id: event.chat_id,
            text: human_success_message(result: result, trace_id: Trace.current_trace_id || "none")
          )
          send_json_envelope_if_enabled(chat_id: event.chat_id, envelope: envelope)
          @out.puts("telegram processed chat=#{event.chat_id} task=#{result.task.id}")
        rescue StandardError => e
          error_envelope = RuntimeResultEnvelope.error(
            trace_id: Trace.current_trace_id || "none",
            message: e.message
          )
          @telegram_client.send_message(
            chat_id: event.chat_id,
            text: human_error_message(message: e.message, trace_id: Trace.current_trace_id || "none")
          )
          send_json_envelope_if_enabled(chat_id: event.chat_id, envelope: error_envelope)
          @err.puts("telegram processing error chat=#{event.chat_id}: #{e.message}")
        ensure
          stop_typing.call if stop_typing
        end
      end
    end

    private

    def interpreter
      @intent_interpreter ||= LlmIntentInterpreter.new(llm_client: nil)
    end

    def trace_system_prompt_for_interpreter(project_context:, architecture_context:)
      unless interpreter.respond_to?(:system_prompt)
        return LlmIntentInterpreter::SYSTEM_PROMPT.strip
      end

      params = interpreter.method(:system_prompt).parameters
      if params.any? { |type, name| [:key, :keyreq].include?(type) && name == :project_context }
        return interpreter.system_prompt(
          project_context: project_context,
          architecture_context: architecture_context
        )
      end
      interpreter.system_prompt
    end

    def resolve_context(event:)
      return TelegramContextResolver::Resolution.new(resolved: true, project_ref: nil, project_path: nil, workstream_id: nil, question: nil) unless @context_resolver

      @context_resolver.resolve(chat_id: event.chat_id, text: event.text)
    end

    def load_prompt_context(project_path:)
      return { project_context: nil, architecture_context: nil } unless @prompt_context_loader

      @prompt_context_loader.build(project_path: project_path)
    rescue StandardError
      { project_context: nil, architecture_context: nil }
    end

    def interpret_with_context(text:, model:, project_context:, architecture_context:)
      params = interpreter.method(:interpret).parameters
      if params.any? { |type, name| [:key, :keyreq].include?(type) && name == :project_context }
        return interpreter.interpret(
          text: text,
          model: model,
          project_context: project_context,
          architecture_context: architecture_context
        )
      end

      interpreter.interpret(text: text, model: model)
    end

    def planner_decision_invalid?(decision)
      reason = decision.finish_reason.to_s
      reason.start_with?("invalid_payload") || reason.start_with?("llm_error")
    end

    def persist_planner_rejection(resolution:, reason:, raw_output:, user_text:)
      return nil unless @planner_rejection_store

      @planner_rejection_store.create(
        project_id: resolution.project_ref,
        project_ref: resolution.project_ref,
        reason: reason,
        raw_output: raw_output,
        user_text: user_text
      )
    rescue StandardError => e
      @err.puts("planner rejection persist failed: #{e.message}")
      nil
    end

    def build_execution_summary(result)
      action_results = if result.respond_to?(:action_results)
                         result.action_results || []
                       else
                         []
                       end
      return nil if action_results.empty?

      total = action_results.size
      failed = action_results.count { |r| r.status != "ok" }
      succeeded = total - failed
      failed_action_ids = action_results.select { |r| r.status != "ok" }.map(&:action_id)
      {
        total_actions: total,
        succeeded_actions: succeeded,
        failed_actions: failed,
        failed_action_ids: failed_action_ids
      }
    end

    def human_success_message(result:, trace_id:)
      parts = []
      parts << "Started task #{result.task.id} in project #{result.project.id}."
      parts << "Workstream: #{result.workstream.id} (state: #{result.workstream.state})."
      execution = build_execution_summary(result)
      if execution
        parts << "Actions: #{execution[:succeeded_actions]}/#{execution[:total_actions]} succeeded, #{execution[:failed_actions]} failed."
      end
      parts << "Trace: #{trace_id}"
      parts.join("\n")
    end

    def human_error_message(message:, trace_id:)
      "Error: #{message}\nTrace: #{trace_id}"
    end

    def human_clarify_message(question:, trace_id:)
      "#{question}\nTrace: #{trace_id}"
    end

    def human_planner_rejection_message(reason:, trace_id:)
      [
        "Planner output was rejected before execution.",
        "Reason: #{reason}",
        "No actions were executed for this turn.",
        "Trace: #{trace_id}"
      ].join("\n")
    end

    def send_json_envelope_if_enabled(chat_id:, envelope:)
      return unless @send_json_envelope

      @telegram_client.send_message(chat_id: chat_id, text: "```json\n#{envelope.to_json_string}\n```")
    end

    def start_typing_keepalive(chat_id)
      stop = false
      mutex = Mutex.new

      begin
        @telegram_client.send_chat_action(chat_id: chat_id, action: "typing")
      rescue StandardError => e
        @err.puts("telegram typing hint failed chat=#{chat_id}: #{e.message}")
      end

      worker = Thread.new do
        loop do
          break if mutex.synchronize { stop }

          begin
            @telegram_client.send_chat_action(chat_id: chat_id, action: "typing")
          rescue StandardError => e
            @err.puts("telegram typing hint failed chat=#{chat_id}: #{e.message}")
          end

          break if mutex.synchronize { stop }
          @typing_sleeper.call(@typing_interval_seconds)
        end
      end

      lambda do
        mutex.synchronize { stop = true }
        worker.join(0.5)
      end
    end
  end
end
