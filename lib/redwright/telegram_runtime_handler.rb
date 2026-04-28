# frozen_string_literal: true

require_relative "trace"
require_relative "runtime_result_envelope"
require_relative "llm_intent_interpreter"
require_relative "telegram_context_resolver"
require_relative "iteration_context_packet_builder"

module Redwright
  class TelegramRuntimeHandler
    MAX_CHANGE_LOOP_ATTEMPTS = 8

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
      clarification_session_store: nil,
      quality_gate_runner: nil,
      send_json_envelope: false,
      max_change_turn_seconds: 180,
      iteration_context_packet_builder: IterationContextPacketBuilder.new,
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
      @clarification_session_store = clarification_session_store
      @quality_gate_runner = quality_gate_runner
      @send_json_envelope = send_json_envelope
      @max_change_turn_seconds = max_change_turn_seconds
      @iteration_context_packet_builder = iteration_context_packet_builder
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
          decision_input = consume_pending_planner_gap_answer(
            chat_id: event.chat_id,
            workstream_id: resolution.workstream_id,
            user_text: event.text
          )
          decision = interpret_with_trace(
            action: decision_input[:action],
            text: decision_input[:text],
            model: @model_name,
            project_context: prompt_context[:project_context],
            architecture_context: prompt_context[:architecture_context],
            workspace_context: prompt_context[:workspace_context]
          )
          control_intent = if decision.respond_to?(:control_intent)
                             decision.control_intent.to_s.strip
                           else
                             "none"
                           end
          suppress_gap_clarify = false
          if %w[cancel_clarification_only proceed_with_current_context].include?(control_intent)
            cancel_scope = control_intent == "cancel_clarification_only" ? "task" : "chat"
            cancel_open_clarifications(
              chat_id: event.chat_id,
              workstream_id: resolution.workstream_id,
              scope: cancel_scope
            )
            suppress_gap_clarify = true
          end
          control = control_from_decision(decision, raw_text: event.text)
          if control
            cancel_open_clarifications(
              chat_id: event.chat_id,
              workstream_id: resolution.workstream_id,
              scope: control[:command] == "stop" ? "chat" : "task"
            )
            control_result = @flow.control(
              project_ref: resolution.project_ref,
              command: control[:command],
              reason: control[:reason],
              workstream_id: resolution.workstream_id
            )
            envelope = RuntimeResultEnvelope.success(
              trace_id: Trace.current_trace_id || "none",
              project_id: control_result.project.id,
              workstream_id: control_result.workstream.id,
              task_id: control_result.task.id,
              state: control_result.workstream.state,
              terminal_reason: "control_#{control[:command]}"
            )
            @telegram_client.send_message(
              chat_id: event.chat_id,
              text: human_success_message(
                result: control_result,
                trace_id: Trace.current_trace_id || "none",
                quality_summary: nil,
                attempts: 1,
                terminal_reason: "control_#{control[:command]}",
                mode: "direct"
              )
            )
            send_json_envelope_if_enabled(chat_id: event.chat_id, envelope: envelope)
            @out.puts("telegram control chat=#{event.chat_id} command=#{control[:command]} task=#{control_result.task.id}")
            return
          end

          gap = suppress_gap_clarify ? nil : highest_value_gap(decision)
          gap_question = gap && gap["question"].to_s.strip
          if gap_question
            @clarification_session_store&.open_planner_gap(
              chat_id: event.chat_id,
              workstream_id: resolution.workstream_id,
              base_message: decision.message,
              gap: gap,
              question_id: gap["id"].to_s.strip.empty? ? nil : gap["id"].to_s.strip
            )
            clarify = RuntimeResultEnvelope.clarify(
              trace_id: Trace.current_trace_id || "none",
              message: gap_question
            )
            @telegram_client.send_message(
              chat_id: event.chat_id,
              text: human_clarify_message(question: gap_question, trace_id: Trace.current_trace_id || "none")
            )
            send_json_envelope_if_enabled(chat_id: event.chat_id, envelope: clarify)
            @out.puts("telegram clarify chat=#{event.chat_id}")
            return
          end

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

          loop_result = if decision.intent == "change"
                          mode_selection = select_change_mode(event_text: event.text, decision: decision)
                          Trace.runtime(
                            trace_id: Trace.current_trace_id || "none",
                            selected_mode: mode_selection[:mode],
                            selected_mode_source: mode_selection[:source]
                          )
                          process_change_turn(
                            mode: mode_selection[:mode],
                            initial_decision: decision,
                            resolution: resolution,
                            prompt_context: prompt_context,
                            original_text: event.text
                          ).merge(mode: mode_selection[:mode])
                        else
                          process_single_turn(
                            decision: decision,
                            resolution: resolution,
                            prompt_context: prompt_context
                          ).merge(attempts: 1, terminal_reason: "single_pass", mode: "direct")
                        end
          result = loop_result[:result]
          quality_summary = loop_result[:quality_summary]
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
            execution: build_execution_summary(
              result,
              quality_summary: quality_summary,
              attempts: loop_result[:attempts],
              terminal_reason: loop_result[:terminal_reason],
              mode: loop_result[:mode]
            ),
            terminal_reason: loop_result[:terminal_reason]
          )
          @telegram_client.send_message(
            chat_id: event.chat_id,
            text: human_success_message(
              result: result,
              trace_id: Trace.current_trace_id || "none",
              quality_summary: quality_summary,
              attempts: loop_result[:attempts],
              terminal_reason: loop_result[:terminal_reason],
              mode: loop_result[:mode]
            )
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

    def interpret_with_trace(action:, text:, model:, project_context:, architecture_context:, workspace_context:)
      Trace.llm_request(
        role: @model_role,
        provider: @model_provider,
        model: @model_name,
        action: action,
        payload_bytes: text.to_s.bytesize,
        system_prompt: trace_system_prompt_for_interpreter(
          project_context: project_context,
          architecture_context: architecture_context,
          workspace_context: workspace_context
        ),
        user_text: text
      )
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      decision = interpret_with_context(
        text: text,
        model: model,
        project_context: project_context,
        architecture_context: architecture_context,
        workspace_context: workspace_context
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
      decision
    end

    def trace_system_prompt_for_interpreter(project_context:, architecture_context:, workspace_context:)
      unless interpreter.respond_to?(:system_prompt)
        return LlmIntentInterpreter::SYSTEM_PROMPT.strip
      end

      kwargs = {
        project_context: project_context,
        architecture_context: architecture_context,
        workspace_context: workspace_context
      }
      call_with_supported_keywords(interpreter.method(:system_prompt), kwargs)
    end

    def resolve_context(event:)
      return TelegramContextResolver::Resolution.new(resolved: true, project_ref: nil, project_path: nil, workstream_id: nil, question: nil) unless @context_resolver

      @context_resolver.resolve(chat_id: event.chat_id, text: event.text)
    end

    def load_prompt_context(project_path:)
      return { project_context: nil, architecture_context: nil, workspace_context: nil, quality: { auto_validate: false } } unless @prompt_context_loader

      @prompt_context_loader.build(project_path: project_path)
    rescue StandardError
      { project_context: nil, architecture_context: nil, workspace_context: nil, quality: { auto_validate: false } }
    end

    def interpret_with_context(text:, model:, project_context:, architecture_context:, workspace_context:)
      kwargs = {
        text: text,
        model: model,
        project_context: project_context,
        architecture_context: architecture_context,
        workspace_context: workspace_context
      }
      call_with_supported_keywords(interpreter.method(:interpret), kwargs)
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

    def run_quality_gate(project_path:, quality_config:)
      return nil unless @quality_gate_runner
      return nil unless quality_config.is_a?(Hash) && quality_config[:auto_validate] == true

      checks = @quality_gate_runner.run(
        project_path: project_path,
        lint_command: quality_config[:lint_command],
        test_command: quality_config[:test_command]
      )
      return nil if checks.empty?

      failed = checks.select { |c| c.status != "ok" }
      Trace.runtime(
        trace_id: Trace.current_trace_id || "none",
        quality_total_checks: checks.size,
        quality_failed_checks: failed.size,
        quality_failed_names: failed.map(&:name).join(",")
      )
      {
        total_checks: checks.size,
        passed_checks: checks.size - failed.size,
        failed_checks: failed.size,
        failed_check_names: failed.map(&:name)
      }
    rescue StandardError => e
      @err.puts("quality gate failed: #{e.message}")
      nil
    end

    def process_single_turn(decision:, resolution:, prompt_context:)
      result = @flow.process(
        project_ref: resolution.project_ref,
        intent: decision.intent,
        message: decision.message,
        actions: decision.respond_to?(:actions) ? decision.actions : [],
        workstream_id: resolution.workstream_id,
        confirm_new_workstream: true,
        blocked_retry_attempts: @blocked_retry_attempts
      )
      quality_summary = run_quality_gate(
        project_path: resolution.project_path,
        quality_config: prompt_context[:quality]
      )
      { result: result, quality_summary: quality_summary }
    end

    def process_change_turn(mode:, initial_decision:, resolution:, prompt_context:, original_text:)
      if mode == "direct"
        return process_single_turn(
          decision: initial_decision,
          resolution: resolution,
          prompt_context: prompt_context
        ).merge(attempts: 1, terminal_reason: "direct_pass")
      end

      process_change_turn_with_micro_loop(
        initial_decision: initial_decision,
        resolution: resolution,
        prompt_context: prompt_context,
        original_text: original_text
      )
    end

    def process_change_turn_with_micro_loop(initial_decision:, resolution:, prompt_context:, original_text:)
      max_attempts = normalized_change_loop_attempts(@blocked_retry_attempts)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + @max_change_turn_seconds.to_i
      decision = initial_decision
      attempts = 0
      last_outcome = nil
      terminal_reason = "success"

      while attempts < max_attempts
        attempts += 1
        Trace.runtime(trace_id: Trace.current_trace_id || "none", micro_loop_attempt: attempts, micro_loop_max_attempts: max_attempts)
        last_outcome = process_single_turn(decision: decision, resolution: resolution, prompt_context: prompt_context)
        quality_summary = last_outcome[:quality_summary]
        if quality_failed?(quality_summary)
          terminal_reason = "quality_failed"
          break if attempts >= max_attempts
          break if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

          refinement_packet = build_refinement_context_packet(
            project_path: resolution.project_path,
            original_text: original_text,
            quality_summary: quality_summary,
            previous_message: decision.message
          )
          Trace.runtime(
            trace_id: Trace.current_trace_id || "none",
            refinement_top_files_count: refinement_packet[:summary][:top_files_count],
            refinement_top_files: refinement_packet[:summary][:top_files].join(",")
          )
          decision = interpret_with_trace(
            action: "intent_refine_with_errors",
            text: refinement_packet[:prompt_text],
            model: @model_name,
            project_context: prompt_context[:project_context],
            architecture_context: prompt_context[:architecture_context],
            workspace_context: prompt_context[:workspace_context]
          )
          if highest_value_gap_question(decision)
            terminal_reason = "clarify"
            break
          end
          if decision.source == "fallback" && planner_decision_invalid?(decision)
            terminal_reason = "planner_rejected_after_retry"
            break
          end
          next
        end

        terminal_reason = "success"
        break
      end

      terminal_reason = classify_change_loop_exit(
        terminal_reason: terminal_reason,
        attempts: attempts,
        max_attempts: max_attempts,
        deadline: deadline
      )
      last_outcome.merge(attempts: attempts, terminal_reason: terminal_reason)
    end

    def normalized_change_loop_attempts(raw)
      value = raw.to_i
      value = 1 if value <= 0
      [value, MAX_CHANGE_LOOP_ATTEMPTS].min
    end

    def classify_change_loop_exit(terminal_reason:, attempts:, max_attempts:, deadline:)
      return "timeout" if terminal_reason == "quality_failed" && Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
      return "max_attempts" if terminal_reason == "quality_failed" && attempts >= max_attempts

      terminal_reason
    end

    def quality_failed?(quality_summary)
      return false if quality_summary.nil?

      quality_summary[:failed_checks].to_i.positive?
    end

    def build_refinement_context_packet(project_path:, original_text:, quality_summary:, previous_message:)
      failed = quality_summary[:failed_check_names] || []
      packet = @iteration_context_packet_builder.build(
        project_path: project_path,
        task_goal: original_text,
        previous_message: previous_message,
        current_errors: [
          "Validation failed after execution.",
          "Failed checks: #{failed.join(', ')}"
        ]
      )
      packet[:prompt_text] = [
        packet[:prompt_text],
        "",
        "Return a corrected execution plan that repairs the failures while preserving the original goal."
      ].join("\n")
      packet
    end

    def build_execution_summary(result, quality_summary: nil, attempts: 1, terminal_reason: "single_pass", mode: nil)
      action_results = if result.respond_to?(:action_results)
                         result.action_results || []
                       else
                         []
                       end
      if action_results.empty? && quality_summary.nil?
        if result.respond_to?(:terminal_reason) && result.terminal_reason
          return { terminal_reason: result.terminal_reason }
        end
        return nil
      end

      total = action_results.size
      failed = action_results.count { |r| r.status != "ok" }
      succeeded = total - failed
      failed_action_ids = action_results.select { |r| r.status != "ok" }.map(&:action_id)
      summary = {
        total_actions: total,
        succeeded_actions: succeeded,
        failed_actions: failed,
        failed_action_ids: failed_action_ids,
        attempts: attempts,
        terminal_reason: terminal_reason
      }
      summary[:mode] = mode if mode
      summary[:quality] = quality_summary if quality_summary
      summary
    end

    def human_success_message(result:, trace_id:, quality_summary:, attempts:, terminal_reason:, mode:)
      parts = []
      parts << "Started task #{result.task.id} in project #{result.project.id}."
      parts << "Workstream: #{result.workstream.id} (state: #{result.workstream.state})."
      execution = build_execution_summary(result, quality_summary: nil, attempts: attempts, terminal_reason: terminal_reason, mode: mode)
      if execution
        parts << "Actions: #{execution[:succeeded_actions]}/#{execution[:total_actions]} succeeded, #{execution[:failed_actions]} failed."
      end
      parts << "Mode: #{mode}."
      parts << "Attempts: #{attempts} (terminal: #{terminal_reason})."
      if quality_summary
        parts << "Quality checks: #{quality_summary[:passed_checks]}/#{quality_summary[:total_checks]} passed, #{quality_summary[:failed_checks]} failed."
      end
      confirmation_hint = confirmation_required_hint(result)
      parts << confirmation_hint if confirmation_hint
      parts << "Trace: #{trace_id}"
      parts.join("\n")
    end

    def human_error_message(message:, trace_id:)
      "Error: #{message}\nTrace: #{trace_id}"
    end

    def human_clarify_message(question:, trace_id:)
      [
        question.to_s,
        "Trace: #{trace_id}"
      ].join("\n")
    end

    def human_planner_rejection_message(reason:, trace_id:)
      [
        "Planner output was rejected before execution.",
        "Reason: #{reason}",
        "No actions were executed for this turn.",
        "Trace: #{trace_id}"
      ].join("\n")
    end

    def control_from_decision(decision, raw_text:)
      return nil unless decision.respond_to?(:intent) && decision.intent.to_s.strip == "meta"

      intent = if decision.respond_to?(:control_intent)
                 decision.control_intent.to_s.strip
               else
                 "none"
               end
      command = control_intent_command_map[intent]
      return nil if command.nil?

      { command: command, reason: raw_text.to_s.strip }
    end

    def control_intent_command_map
      {
        "proceed_with_current_context" => "resume",
        "cancel_task" => "stop",
        "cancel_all" => "stop"
      }
    end

    def cancel_open_clarifications(chat_id:, workstream_id:, scope:)
      return unless @clarification_session_store

      if scope == "chat"
        @clarification_session_store.cancel_open(chat_id: chat_id)
      else
        @clarification_session_store.cancel_open(chat_id: chat_id, workstream_id: workstream_id)
      end
    rescue StandardError => e
      @err.puts("clarification cancel failed chat=#{chat_id}: #{e.message}")
    end

    def select_change_mode(event_text:, decision:)
      explicit = extract_mode_override(event_text)
      return { mode: explicit, source: "override" } if explicit

      normalized = "#{event_text}\n#{decision.message}".downcase
      if normalized.match?(/\b(plan|planning|slice|spec|tracker|pr|alignment|draft)\b/)
        return { mode: "structured", source: "inferred" }
      end

      { mode: "structured", source: "default" }
    end

    def extract_mode_override(text)
      match = text.to_s.downcase.match(/\bmode\s*[:=]\s*(structured|direct)\b/)
      return nil unless match

      match[1]
    end

    def highest_value_gap_question(decision)
      gap = highest_value_gap(decision)
      return nil unless gap

      gap["question"].to_s.strip
    end

    def highest_value_gap(decision)
      gaps = if decision.respond_to?(:gaps)
               decision.gaps
             else
               []
             end
      return nil unless gaps.is_a?(Array) && !gaps.empty?

      unresolved = gaps.select { |g| g.is_a?(Hash) && g["resolved"] == false && !g["question"].to_s.strip.empty? }
      return nil if unresolved.empty?

      unresolved.min_by { |g| [g["priority"].to_i <= 0 ? 9 : g["priority"].to_i, g["id"].to_s] }
    end

    def consume_pending_planner_gap_answer(chat_id:, workstream_id:, user_text:)
      pending = @clarification_session_store&.get_open(chat_id: chat_id, workstream_id: workstream_id)
      return { text: user_text, action: "intent_interpret" } unless pending && pending.gap_type == "planner_gap"

      base = pending.payload.fetch("base_message", "").to_s.strip
      gap_field = pending.payload.fetch("gap", {}).fetch("field", "").to_s.strip
      merged = if base.empty?
                 user_text.to_s
               else
                 [base, "Clarification#{gap_field.empty? ? '' : " for #{gap_field}"}: #{user_text}"].join("\n")
               end

      @clarification_session_store&.advance(
        chat_id: chat_id,
        session_id: pending.id,
        resolved_fields: { gap_field.empty? ? "clarification_answer" : gap_field => user_text.to_s },
        status: "closed",
        last_question_id: pending.last_question_id
      )

      { text: merged, action: "intent_interpret_with_gap_answer" }
    end

    def send_json_envelope_if_enabled(chat_id:, envelope:)
      return unless @send_json_envelope

      @telegram_client.send_message(chat_id: chat_id, text: "```json\n#{envelope.to_json_string}\n```")
    end

    def confirmation_required_hint(result)
      action_results = if result.respond_to?(:action_results)
                         result.action_results || []
                       else
                         []
                       end
      blocked = action_results.select do |r|
        next false unless r.respond_to?(:status) && r.status != "ok"
        next false unless r.respond_to?(:error_message) && r.error_message.to_s == "confirmation_required"

        if r.respond_to?(:action_type)
          %w[git_commit git_push].include?(r.action_type.to_s)
        else
          true
        end
      end
      return nil if blocked.empty?

      ids = blocked.map { |r| r.respond_to?(:action_id) ? r.action_id : "unknown" }.join(", ")
      "Commit/push actions were blocked by confirmation policy (#{ids}). Ask to retry with explicit confirmation."
    end

    def call_with_supported_keywords(method_obj, kwargs)
      params = method_obj.parameters
      accepts_keyrest = params.any? { |type, _name| type == :keyrest }
      return method_obj.call(**kwargs) if accepts_keyrest

      allowed = params.select { |type, _name| [:key, :keyreq].include?(type) }.map(&:last)
      filtered = kwargs.select { |key, _| allowed.include?(key) }
      method_obj.call(**filtered)
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
