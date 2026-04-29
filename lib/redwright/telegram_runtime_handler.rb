# frozen_string_literal: true

require_relative "trace"
require_relative "runtime_result_envelope"
require_relative "llm_intent_interpreter"
require_relative "telegram_context_resolver"
require_relative "iteration_context_packet_builder"
require_relative "bootstrap_minimum_gate"
require_relative "hint_normalizer"
require_relative "skill_router"
require_relative "skill_subloop_executor"
require_relative "feedback_normalizer"

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
      max_no_progress_attempts: 2,
      max_repeated_fingerprint_attempts: 2,
      iteration_context_packet_builder: IterationContextPacketBuilder.new,
      typing_interval_seconds: 4.0,
      typing_sleeper: ->(seconds) { sleep(seconds) },
      bootstrap_minimum_gate: BootstrapMinimumGate.new,
      hint_normalizer: HintNormalizer.new,
      skill_router: SkillRouter.new,
      skill_subloop_executor: SkillSubloopExecutor.new,
      feedback_normalizer: FeedbackNormalizer.new,
      execution_feedback_store: nil
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
      @max_no_progress_attempts = [max_no_progress_attempts.to_i, 1].max
      @max_repeated_fingerprint_attempts = [max_repeated_fingerprint_attempts.to_i, 1].max
      @iteration_context_packet_builder = iteration_context_packet_builder
      @typing_interval_seconds = typing_interval_seconds
      @typing_sleeper = typing_sleeper
      @bootstrap_minimum_gate = bootstrap_minimum_gate
      @hint_normalizer = hint_normalizer
      @skill_router = skill_router
      @skill_subloop_executor = skill_subloop_executor
      @feedback_normalizer = feedback_normalizer
      @execution_feedback_store = execution_feedback_store
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
          slash = parse_slash_command(event.text)
          explicit_skill_name = slash && slash[:kind] == "skill" ? slash[:skill_name] : ""
          if slash && slash[:kind] == "control"
            cancel_open_clarifications(
              chat_id: event.chat_id,
              workstream_id: resolution.workstream_id,
              scope: slash[:command] == "stop" ? "chat" : "task"
            )
            control_result = @flow.control(
              project_ref: resolution.project_ref,
              command: slash[:command],
              reason: slash[:reason],
              workstream_id: resolution.workstream_id
            )
            envelope = RuntimeResultEnvelope.success(
              trace_id: Trace.current_trace_id || "none",
              project_id: control_result.project.id,
              workstream_id: control_result.workstream.id,
              task_id: control_result.task.id,
              state: control_result.workstream.state,
              terminal_reason: "control_#{slash[:command]}"
            )
            @telegram_client.send_message(
              chat_id: event.chat_id,
              text: human_success_message(
                result: control_result,
                trace_id: Trace.current_trace_id || "none",
                quality_summary: nil,
                attempts: 1,
                terminal_reason: "control_#{slash[:command]}",
                mode: "direct"
              )
            )
            send_json_envelope_if_enabled(chat_id: event.chat_id, envelope: envelope)
            @out.puts("telegram control chat=#{event.chat_id} command=#{slash[:command]} task=#{control_result.task.id}")
            return
          end

          if confirmation_reply_only?(event.text) && active_planner_gap(chat_id: event.chat_id, workstream_id: resolution.workstream_id).nil?
            clarify = RuntimeResultEnvelope.clarify(
              trace_id: Trace.current_trace_id || "none",
              message: "No active question to confirm. Send a concrete request or ask for status."
            )
            @telegram_client.send_message(
              chat_id: event.chat_id,
              text: human_clarify_message(
                question: "No active question to confirm. Send a concrete request or ask for status.",
                trace_id: Trace.current_trace_id || "none"
              )
            )
            send_json_envelope_if_enabled(chat_id: event.chat_id, envelope: clarify)
            @out.puts("telegram clarify chat=#{event.chat_id}")
            return
          end

          normalized_text = if slash && (slash[:kind] == "planner_hint" || slash[:kind] == "skill")
                              slash[:planner_text]
                            else
                              normalize_hint_text(event.text)
                            end
          decision_input = consume_pending_planner_gap_answer(
            chat_id: event.chat_id,
            workstream_id: resolution.workstream_id,
            user_text: normalized_text
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
            # Keep cancellation scoped to the active task/workstream clarification.
            cancel_scope = "task"
            cancel_open_clarifications(
              chat_id: event.chat_id,
              workstream_id: resolution.workstream_id,
              scope: cancel_scope
            )
            suppress_gap_clarify = true
          end
          control = control_from_decision(decision, raw_text: event.text)
          control ||= control_from_operational(decision, raw_text: event.text)
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

          skill_activation = @skill_router.resolve(
            explicit_skill_name: explicit_skill_name,
            decision: decision
          )
          apply_skill_activation(decision: decision, activation: skill_activation)
          emit_skill_activation_telemetry(chat_id: event.chat_id, activation: skill_activation)
          run_skill_subloop_if_needed(
            decision: decision,
            activation: skill_activation,
            chat_id: event.chat_id,
            workstream_id: resolution.workstream_id
          )

          gate_result = evaluate_bootstrap_gate(decision: decision, suppress_gap_clarify: suppress_gap_clarify)
          gap = gate_result[:technical_blocking_gap]
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
          if result.nil?
            if loop_result[:terminal_reason].to_s == "clarify"
              question = loop_result[:clarify_question].to_s.strip
              question = "Clarification needed before execution can continue." if question.empty?
              clarify = RuntimeResultEnvelope.clarify(
                trace_id: Trace.current_trace_id || "none",
                message: question
              )
              @telegram_client.send_message(
                chat_id: event.chat_id,
                text: human_clarify_message(question: question, trace_id: Trace.current_trace_id || "none")
              )
              send_json_envelope_if_enabled(chat_id: event.chat_id, envelope: clarify)
              @out.puts("telegram clarify chat=#{event.chat_id}")
              return
            end

            raise "runtime_result_missing: terminal_reason=#{loop_result[:terminal_reason]}"
          end
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
      terminal_clarify_question = nil
      no_progress_streak = 0
      repeated_fingerprint_streak = 0
      last_fingerprints = nil

      while attempts < max_attempts
        attempts += 1
        Trace.runtime(trace_id: Trace.current_trace_id || "none", micro_loop_attempt: attempts, micro_loop_max_attempts: max_attempts)
        begin
          last_outcome = process_single_turn(decision: decision, resolution: resolution, prompt_context: prompt_context)
        rescue StandardError => e
          if recoverable_runtime_error?(e.message) && attempts < max_attempts && Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
            refinement_packet = build_runtime_error_refinement_packet(
              project_path: resolution.project_path,
              original_text: original_text,
              previous_message: decision.message,
              runtime_error: e.message
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
              terminal_clarify_question = highest_value_gap_question(decision)
              break
            end
            if decision.source == "fallback" && planner_decision_invalid?(decision)
              terminal_reason = "planner_rejected_after_retry"
              break
            end
            next
          end

          raise
        end
        quality_summary = last_outcome[:quality_summary]
        feedback = @feedback_normalizer.normalize(
          quality_summary: quality_summary,
          action_results: last_outcome[:result]&.action_results
        )
        persist_execution_feedback(
          result: last_outcome[:result],
          attempt: attempts,
          feedback: feedback
        )
        fingerprint_list = feedback.fingerprints.map { |entry| entry["fingerprint"].to_s }.sort
        no_progress_streak = fingerprint_list.empty? ? no_progress_streak + 1 : 0
        if !fingerprint_list.empty? && last_fingerprints == fingerprint_list
          repeated_fingerprint_streak += 1
        else
          repeated_fingerprint_streak = 0
        end
        last_fingerprints = fingerprint_list

        if no_progress_streak >= @max_no_progress_attempts
          terminal_reason = "no_progress"
          break
        end
        if repeated_fingerprint_streak >= @max_repeated_fingerprint_attempts
          terminal_reason = "repeated_fingerprint"
          break
        end

        if quality_failed?(quality_summary)
          terminal_reason = "quality_failed"
          break if attempts >= max_attempts
          break if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

          refinement_packet = build_refinement_context_packet(
            project_path: resolution.project_path,
            original_text: original_text,
            quality_summary: quality_summary,
            previous_message: decision.message,
            normalized_failures: feedback.normalized_failures,
            last_execution_results: feedback.execution_results
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
            terminal_clarify_question = highest_value_gap_question(decision)
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
        deadline_reached: Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
      )
      outcome = last_outcome || {
        result: nil,
        quality_summary: nil
      }
      outcome.merge(
        attempts: attempts,
        terminal_reason: terminal_reason,
        clarify_question: terminal_clarify_question
      )
    end

    def normalized_change_loop_attempts(raw)
      value = raw.to_i
      value = 1 if value <= 0
      [value, MAX_CHANGE_LOOP_ATTEMPTS].min
    end

    def classify_change_loop_exit(terminal_reason:, attempts:, max_attempts:, deadline_reached:)
      return "timeout" if terminal_reason == "quality_failed" && deadline_reached
      return "max_attempts" if terminal_reason == "quality_failed" && attempts >= max_attempts

      terminal_reason
    end

    def quality_failed?(quality_summary)
      return false if quality_summary.nil?

      quality_summary[:failed_checks].to_i.positive?
    end

    def build_refinement_context_packet(project_path:, original_text:, quality_summary:, previous_message:, normalized_failures:, last_execution_results:)
      failed = quality_summary[:failed_check_names] || []
      packet = @iteration_context_packet_builder.build(
        project_path: project_path,
        task_goal: original_text,
        previous_message: previous_message,
        current_errors: [
          "Validation failed after execution.",
          "Failed checks: #{failed.join(', ')}"
        ],
        normalized_failures: normalized_failures,
        last_execution_results: last_execution_results
      )
      packet[:prompt_text] = [
        packet[:prompt_text],
        "",
        "Return a corrected execution plan that repairs the failures while preserving the original goal."
      ].join("\n")
      packet
    end

    def build_runtime_error_refinement_packet(project_path:, original_text:, previous_message:, runtime_error:)
      packet = @iteration_context_packet_builder.build(
        project_path: project_path,
        task_goal: original_text,
        previous_message: previous_message,
        current_errors: [
          "Execution failed before validation.",
          "Runtime error: #{runtime_error}"
        ],
        normalized_failures: [
          {
            "failure_class" => classify_runtime_error(runtime_error),
            "fingerprint" => runtime_error.to_s[0, 180],
            "summary" => runtime_error.to_s
          }
        ],
        last_execution_results: []
      )
      packet[:prompt_text] = [
        packet[:prompt_text],
        "",
        "Return a corrected execution plan that fixes the runtime error and keeps the original objective."
      ].join("\n")
      packet
    end

    def recoverable_runtime_error?(message)
      msg = message.to_s
      recoverable_macro_error?(msg) || msg.include?("action_failed id=")
    end

    def recoverable_macro_error?(message)
      msg = message.to_s
      msg.include?("write_files_missing_files") ||
        msg.include?("write_files_invalid_content") ||
        msg.include?("run_commands_missing_cmds") ||
        msg.include?("run_commands_invalid_cmd") ||
        msg.include?("run_command_missing_cmd")
    end

    def classify_runtime_error(message)
      return "macro_shape_error" if recoverable_macro_error?(message)

      "execution_error"
    end

    def persist_execution_feedback(result:, attempt:, feedback:)
      return unless @execution_feedback_store
      return unless result&.respond_to?(:task) && result.task
      return unless result.respond_to?(:workstream) && result.workstream

      feedback.fingerprints.each do |entry|
        @execution_feedback_store.create(
          trace_id: Trace.current_trace_id || "none",
          workstream_id: result.workstream.id,
          task_id: result.task.id,
          attempt: attempt,
          failure_class: entry["failure_class"],
          fingerprint: entry["fingerprint"],
          details: {
            normalized_failures: feedback.normalized_failures,
            execution_results: feedback.execution_results
          }
        )
      end
    rescue StandardError => e
      @err.puts("execution feedback persist failed: #{e.message}")
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
      command ||= inferred_control_command(raw_text) if intent == "none"
      return nil if command.nil?

      { command: command, reason: raw_text.to_s.strip }
    end

    def control_from_operational(decision, raw_text:)
      return nil unless decision.respond_to?(:operational_intent)

      intent = decision.operational_intent.to_s.strip
      return nil if intent.empty? || intent == "none"

      map = {
        "task_pause" => "pause",
        "task_resume" => "resume",
        "task_cancel" => "stop",
        "plan_continue" => "resume",
        "plan_stop_and_apply" => "resume"
      }
      command = map[intent]
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

    def inferred_control_command(raw_text)
      text = raw_text.to_s.strip.downcase
      return nil if text.empty?

      return "stop" if text.match?(/\A(cancel|cancelar|cancela|annulla|annullare|stop|deten|detener|parar|para)\b/)
      return "pause" if text.match?(/\A(pause|pausa|pausar)\b/)
      return "resume" if text.match?(/\A(resume|resumir|continua|continuar|continue|proceed|segui|seguir)\b/)

      nil
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

    def evaluate_bootstrap_gate(decision:, suppress_gap_clarify:)
      return { technical_blocking_gap: nil } if suppress_gap_clarify

      gate = @bootstrap_minimum_gate.evaluate(
        intent: decision.intent,
        actions: decision.respond_to?(:actions) ? decision.actions : [],
        gaps: decision.respond_to?(:gaps) ? decision.gaps : []
      )

      technical = gate[:technical_blocking_gaps] || []
      optional = gate[:alignment_optional_gaps] || []
      Trace.runtime(
        trace_id: Trace.current_trace_id || "none",
        bootstrap_technical_gaps: technical.size,
        bootstrap_optional_gaps: optional.size
      )

      {
        technical_blocking_gap: highest_priority_gap(technical)
      }
    end

    def highest_priority_gap(gaps)
      return nil unless gaps.is_a?(Array) && !gaps.empty?

      gaps.min_by { |g| [g["priority"].to_i <= 0 ? 9 : g["priority"].to_i, g["id"].to_s] }
    end

    def consume_pending_planner_gap_answer(chat_id:, workstream_id:, user_text:)
      pending = active_planner_gap(chat_id: chat_id, workstream_id: workstream_id)
      return { text: user_text, action: "intent_interpret" } unless pending && pending.gap_type == "planner_gap"

      base = pending.payload.fetch("base_message", "").to_s.strip
      gap_field = pending.payload.fetch("gap", {}).fetch("field", "").to_s.strip
      answer = user_text.to_s
      continue_semantic = continue_with_current_context_semantic?(answer)
      merged = if continue_semantic
                 base.empty? ? "Continue with current context and execute using existing assumptions." : base
               elsif base.empty?
                 answer
               else
                 [base, "Clarification#{gap_field.empty? ? '' : " for #{gap_field}"}: #{answer}"].join("\n")
               end

      @clarification_session_store&.advance(
        chat_id: chat_id,
        session_id: pending.id,
        resolved_fields: {
          gap_field.empty? ? "clarification_answer" : gap_field => answer,
          "continue_with_current_context" => continue_semantic
        },
        status: "closed",
        last_question_id: pending.last_question_id
      )

      {
        text: merged,
        action: continue_semantic ? "intent_interpret_with_current_context" : "intent_interpret_with_gap_answer"
      }
    end

    def active_planner_gap(chat_id:, workstream_id:)
      pending = @clarification_session_store&.get_open(chat_id: chat_id, workstream_id: workstream_id)
      pending ||= @clarification_session_store&.get_open(chat_id: chat_id)
      pending
    end

    def confirmation_reply_only?(text)
      normalized = text.to_s.strip.downcase
      return false if normalized.empty?

      %w[yes y si sí no n nope].include?(normalized)
    end

    def continue_with_current_context_semantic?(text)
      normalized = text.to_s.strip.downcase
      return false if normalized.empty?

      phrases = [
        "continue",
        "continue with current context",
        "continue with what you have",
        "proceed with current context",
        "no more questions continue",
        "no more questions. continue",
        "no more questions, continue",
        "stop asking and continue",
        "stop asking questions and continue",
        "continua",
        "continua con lo que tengas",
        "no mas preguntas continua",
        "no más preguntas continua",
        "no mas preguntas. continua",
        "no más preguntas. continua",
        "para con las preguntas y continua",
        "para con las preguntas y continua implementando",
        "segui con lo que tenes",
        "sigue con lo que tengas"
      ]
      phrases.any? { |phrase| normalized == phrase }
    end

    def parse_slash_command(text)
      raw = text.to_s.strip
      return nil unless raw.start_with?("/")

      command, *rest = raw.split(/\s+/, 2)
      arg = rest.first.to_s.strip

      case command.downcase
      when "/pause"
        { kind: "control", command: "pause", reason: raw }
      when "/resume"
        { kind: "control", command: "resume", reason: raw }
      when "/cancel"
        { kind: "control", command: "stop", reason: raw }
      when "/continue"
        { kind: "planner_hint", planner_text: "Continue with current context and execute using existing assumptions." }
      when "/status"
        { kind: "planner_hint", planner_text: "Show runtime status for the current active project and workstream." }
      when "/project"
        return { kind: "planner_hint", planner_text: "Switch active project to #{arg.sub(/^switch\s+/i, "")}." } if arg.match?(/^switch\s+/i)
        return { kind: "planner_hint", planner_text: "Create a new project named #{arg.sub(/^new\s+/i, "")} and set it active." } if arg.match?(/^new\s+/i)
        return { kind: "planner_hint", planner_text: "List known projects and show aliases." } if arg.match?(/^list$/i)
        return { kind: "planner_hint", planner_text: "Show the current active project id, alias, and workspace path." } if arg.match?(/^where$/i)
        nil
      when "/repo"
        return { kind: "planner_hint", planner_text: "Clone repository #{arg.sub(/^clone\s+/i, "")} into the workspace and register it as a project." } if arg.match?(/^clone\s+/i)
        return { kind: "planner_hint", planner_text: "Show repository status for the active project, including branch and dirty files." } if arg.match?(/^status$/i)
        return { kind: "planner_hint", planner_text: "Undo the latest safe repository changes in the active project using runtime guardrails." } if arg.match?(/^undo$/i)
        nil
      when "/task"
        return { kind: "control", command: "pause", reason: raw } if arg.match?(/^pause$/i)
        return { kind: "control", command: "resume", reason: raw } if arg.match?(/^resume$/i)
        return { kind: "control", command: "stop", reason: raw } if arg.match?(/^cancel$/i)
        nil
      when "/plan"
        return { kind: "planner_hint", planner_text: "Start an explicit planning and slicing workflow for the current request." } if arg.match?(/^start$/i)
        return { kind: "planner_hint", planner_text: "Continue with current context and execute using existing assumptions." } if arg.match?(/^continue$/i)
        return { kind: "planner_hint", planner_text: "Stop asking clarification questions and continue implementation with the current accepted assumptions." } if arg.match?(/^stop-and-apply$/i)
        nil
      when "/trace"
        return { kind: "planner_hint", planner_text: "Enable runtime trace output for this session." } if arg.match?(/^on$/i)
        return { kind: "planner_hint", planner_text: "Disable runtime trace output for this session." } if arg.match?(/^off$/i)
        return { kind: "planner_hint", planner_text: "Show current runtime trace status for this session." } if arg.match?(/^status$/i)
        nil
      when "/help"
        { kind: "planner_hint", planner_text: "Show help for runtime commands: /project, /repo, /task, /plan, /trace, /skill." }
      when "/skills"
        { kind: "planner_hint", planner_text: "List available skills and how to trigger each one." }
      when "/skill"
        return nil if arg.empty?

        {
          kind: "skill",
          skill_name: arg,
          planner_text: "Activate skill '#{arg}' in explicit mode for this turn."
        }
      else
        nil
      end
    end

    def apply_skill_activation(decision:, activation:)
      return unless decision && activation

      decision.skill_requested = activation.name if decision.respond_to?(:skill_requested=)
      decision.skill_mode = activation.mode if decision.respond_to?(:skill_mode=)
    end

    def emit_skill_activation_telemetry(chat_id:, activation:)
      return unless activation

      Trace.runtime(
        trace_id: Trace.current_trace_id || "none",
        skill_name: activation.name,
        skill_mode: activation.mode,
        skill_confidence: activation.confidence,
        skill_reason: activation.reason
      )
      @out.puts(
        "telegram skill chat=#{chat_id} name=#{activation.name} mode=#{activation.mode} " \
        "confidence=#{activation.confidence} reason=#{activation.reason}"
      )
    end

    def run_skill_subloop_if_needed(decision:, activation:, chat_id:, workstream_id:)
      return unless activation
      return unless decision.respond_to?(:skill_actions)

      actions = decision.skill_actions
      return unless actions.is_a?(Array) && !actions.empty?

      result = @skill_subloop_executor.run(
        actions: actions,
        cancel_requested: lambda {
          pending = @clarification_session_store&.get_open(chat_id: chat_id, workstream_id: workstream_id)
          pending && pending.gap_type == "control_stop"
        }
      ) do |_action|
        { status: "ok" }
      end

      Trace.runtime(
        trace_id: Trace.current_trace_id || "none",
        skill_subloop_status: result.status,
        skill_subloop_terminal_reason: result.terminal_reason,
        skill_subloop_attempts: result.attempts,
        skill_subloop_executed_actions: result.executed_actions
      )
      @out.puts(
        "telegram skill_subloop chat=#{chat_id} status=#{result.status} " \
        "reason=#{result.terminal_reason} attempts=#{result.attempts} executed_actions=#{result.executed_actions}"
      )
    end

    def normalize_hint_text(text)
      return text.to_s unless @hint_normalizer

      result = @hint_normalizer.normalize(text.to_s)
      result.normalized_text.to_s
    rescue StandardError
      text.to_s
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
