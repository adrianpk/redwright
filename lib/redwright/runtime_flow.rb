# frozen_string_literal: true

require_relative "trace"
require_relative "skill_dispatcher"
require_relative "action_normalizer"
require_relative "planner_contract"
require_relative "alignment_contract"
require_relative "psam_store"
require_relative "alignment_question_engine"
require_relative "alignment_interruption_store"
require_relative "alignment_sufficiency_heuristic"
require_relative "runtime_state_contract"

module Redwright
  FlowResult = Struct.new(
    :project, :workstream, :task, :alignment, :functional_spec_path, :technical_spec_path, :action_results,
    :terminal_reason,
    keyword_init: true
  )

  class RuntimeFlow
    def initialize(
      project_store:,
      workstream_store:,
      task_store:,
      alignment_store:,
      plan_spec_store: nil,
      primitive_executor: nil,
      action_execution_store: nil,
      psam_store: nil,
      alignment_interruption_store: nil,
      alignment_question_engine: nil,
      alignment_max_turns: 8,
      alignment_sufficiency_heuristic: AlignmentSufficiencyHeuristic.new,
      non_coding_model: "gpt-5-mini",
      skill_dispatcher: SkillDispatcher.new,
      action_normalizer: ActionNormalizer.new
    )
      @project_store = project_store
      @workstream_store = workstream_store
      @task_store = task_store
      @alignment_store = alignment_store
      @plan_spec_store = plan_spec_store
      @primitive_executor = primitive_executor
      @action_execution_store = action_execution_store
      @psam_store = psam_store
      @alignment_interruption_store = alignment_interruption_store
      @alignment_question_engine = alignment_question_engine
      @alignment_max_turns = [alignment_max_turns.to_i, 1].max
      @alignment_sufficiency_heuristic = alignment_sufficiency_heuristic
      @non_coding_model = non_coding_model
      @skill_dispatcher = skill_dispatcher
      @action_normalizer = action_normalizer
    end

    def process(
      project_ref:,
      intent:,
      message:,
      actions: [],
      workstream_id: nil,
      confirm_new_workstream: false,
      blocked_retry_attempts: 1
    )
      Trace.with_trace_id(Trace.current_trace_id) do
        retries = [blocked_retry_attempts.to_i, 1].max
        attempts = 0

        begin
          attempts += 1
          return process_once(
            project_ref: project_ref,
            intent: intent,
            message: message,
            actions: actions,
            workstream_id: workstream_id,
            confirm_new_workstream: confirm_new_workstream
          )
        rescue ArgumentError
          raise
        rescue StandardError => e
          retry if attempts < retries

          raise RuntimeError, "blocked after #{retries} attempt(s): #{e.message}"
        end
      end
    end

    def control(project_ref:, command:, reason: nil, workstream_id: nil)
      project = @project_store.resolve(project_ref)
      raise ArgumentError, "project not found" unless project

      workstream = if workstream_id && !workstream_id.empty?
                     @workstream_store.get(workstream_id)
                   else
                     @workstream_store.find_latest_for_project(project_id: project.id)
                   end
      raise ArgumentError, "no workstream found" unless workstream
      raise ArgumentError, "workstream does not belong to project" unless workstream.project_id == project.id

      case command
      when "pause"
        pause_workstream(project: project, workstream: workstream, reason: reason || "user_pause")
      when "stop"
        stop_workstream(project: project, workstream: workstream, reason: reason || "user_stop")
      when "resume"
        resume_workstream(project: project, workstream: workstream)
      else
        raise ArgumentError, "unsupported control command: #{command}"
      end
    end

    private

    def process_once(project_ref:, intent:, message:, actions:, workstream_id:, confirm_new_workstream:)
      project = @project_store.resolve(project_ref)
      raise ArgumentError, "project not found" unless project

      @project_store.mark_active(project.id)

      workstream = resolve_or_create_workstream(
        project: project,
        intent: intent,
        workstream_id: workstream_id,
        confirm_new_workstream: confirm_new_workstream
      )

      if intent == "plan"
        return process_plan(workstream: workstream, message: message, project: project)
      end

      task = @task_store.create(workstream_id: workstream.id, description: message, status: "pending")
      action_results = execute_actions(project: project, task: task, actions: actions)
      workstream = update_workstream_state_checked(workstream: workstream, next_state: "executing")
      Trace.runtime({
        trace_id: Trace.current_trace_id || "none",
        project_id: project.id,
        workstream_id: workstream.id,
        task_id: task.id,
        state: workstream.state
      })
      FlowResult.new(
        project: project,
        workstream: workstream,
        task: task,
        alignment: nil,
        functional_spec_path: nil,
        technical_spec_path: nil,
        action_results: action_results,
        terminal_reason: "executing"
      )
    end

    def resolve_or_create_workstream(project:, intent:, workstream_id:, confirm_new_workstream:)
      if workstream_id && !workstream_id.empty?
        existing = @workstream_store.get(workstream_id)
        raise ArgumentError, "workstream not found" unless existing
        raise ArgumentError, "workstream does not belong to project" unless existing.project_id == project.id

        return existing
      end

      if intent == "plan"
        open_plan = @workstream_store.find_latest(
          project_id: project.id,
          intent: "plan",
          states: ["collecting_context", "waiting_user", "ready"]
        )
        return open_plan if open_plan
      end

      if intent == "resume"
        latest = @workstream_store.find_latest_for_project(
          project_id: project.id,
          states: ["collecting_context", "waiting_user", "executing", "ready", "blocked", "suspended"]
        )
        raise ArgumentError, "no resumable workstream found" unless latest

        return latest
      end

      if intent != "plan"
        latest = @workstream_store.find_latest_for_project(
          project_id: project.id,
          states: ["collecting_context", "waiting_user", "executing", "ready"]
        )
        return latest if latest
      end

      initial_state = intent == "plan" ? "collecting_context" : "executing"
      if !confirm_new_workstream && intent != "plan"
        raise ArgumentError, "new workstream requires confirmation (--confirm-new-workstream)"
      end

      @workstream_store.create(project_id: project.id, intent: intent, state: initial_state)
    end

    def process_plan(workstream:, message:, project:)
      session = @alignment_store.ensure_session(workstream.id)

      if session.pending_question
        persist_psam_answer(workstream_id: workstream.id, step_index: session.step_index, answer: message)
        session = @alignment_store.answer_pending(workstream.id, message)
      end

      turn = next_alignment_turn(workstream: workstream, message: message)
      if turn.status == "ready"
        session = @alignment_store.mark_ready(workstream.id)
        return finalize_ready_plan(project: project, workstream: workstream, session: session, terminal_reason: "ready")
      end

      answered_turns_count = @alignment_store.turns(workstream.id).size
      if @alignment_sufficiency_heuristic&.sufficient?(objective: message, answered_turns_count: answered_turns_count)
        session = @alignment_store.mark_ready(workstream.id)
        return finalize_ready_plan(project: project, workstream: workstream, session: session, terminal_reason: "ready")
      end

      if session.step_index >= @alignment_max_turns
        workstream = update_workstream_state_checked(workstream: workstream, next_state: "blocked")
        task = @task_store.create(workstream_id: workstream.id, description: "alignment max turns reached", status: "blocked")
        return FlowResult.new(
          project: project,
          workstream: workstream,
          task: task,
          alignment: session,
          functional_spec_path: nil,
          technical_spec_path: nil,
          action_results: [],
          terminal_reason: "max_turns"
        )
      end

      persist_psam_question(workstream_id: workstream.id, step_index: session.step_index, turn: turn)
      session = @alignment_store.set_pending_question(workstream.id, question: turn.question, unresolved_count: 1)
      workstream = update_plan_workstream_state_checked(workstream: workstream, next_state: "waiting_user")
      task = @task_store.create(workstream_id: workstream.id, description: "alignment question: #{session.pending_question}", status: "waiting_user")
      FlowResult.new(
        project: project,
        workstream: workstream,
        task: task,
        alignment: session,
        functional_spec_path: nil,
        technical_spec_path: nil,
        action_results: [],
        terminal_reason: "continue"
      )
    end

    def next_alignment_turn(workstream:, message:)
      return fallback_alignment_turn if @alignment_question_engine.nil?

      prior_turns = @alignment_store.turns(workstream.id)
      @alignment_question_engine.next_turn(
        model: @non_coding_model,
        objective: message,
        prior_turns: prior_turns
      )
    end

    def fallback_alignment_turn
      AlignmentQuestionEngine::Turn.new(
        status: "continue",
        question: "What is the minimal acceptance criteria for this task?",
        recommendation: "Define the smallest verifiable outcome first.",
        rationale: "A minimal target reduces ambiguity and iteration waste.",
        decision_node: "planning.acceptance_criteria",
        tags: %w[scope acceptance],
        completion_status: "open",
        source: "fallback",
        finish_reason: "engine_not_configured"
      )
    end

    def persist_psam_question(workstream_id:, step_index:, turn:)
      return unless @psam_store

      question_id = @psam_store.create_question(
        workstream_id: workstream_id,
        step_index: step_index,
        question: turn.question,
        recommendation: turn.recommendation,
        rationale: turn.rationale,
        decision_node: turn.decision_node,
        completion_status: turn.completion_status
      )
      turn.tags.each { |tag| @psam_store.add_tag(question_id: question_id, tag: tag) }
    end

    def persist_psam_answer(workstream_id:, step_index:, answer:)
      return unless @psam_store

      question = @psam_store.find_question(workstream_id: workstream_id, step_index: step_index)
      return unless question
      return if @psam_store.answer_exists?(question_id: question[:id])

      @psam_store.create_answer(question_id: question[:id], answer: answer)
    end

    def update_plan_workstream_state_checked(workstream:, next_state:)
      unless AlignmentContract.allowed_transition?(from: workstream.state, to: next_state)
        raise ArgumentError, "invalid_alignment_transition from=#{workstream.state} to=#{next_state}"
      end

      @workstream_store.update_state(workstream.id, next_state)
    end

    def execute_actions(project:, task:, actions:)
      return [] if actions.nil? || actions.empty?
      raise ArgumentError, "primitive executor is not configured" unless @primitive_executor

      normalized_actions = @action_normalizer.normalize(actions)
      input_count = actions.size
      expanded_count = normalized_actions.size
      macro_types = actions
                    .map { |a| a["type"] }
                    .compact
                    .select { |t| PlannerContract::ACTION_MACRO_TYPES.include?(t) }
                    .uniq
      Trace.runtime({
        trace_id: Trace.current_trace_id || "none",
        input_actions: input_count,
        expanded_actions: expanded_count,
        macro_types: macro_types.join(",")
      })
      results = []
      normalized_actions.each do |action|
        action_context = {
          project_id: project.id,
          project_path: project.path,
          task_id: task.id
        }
        routed_action = @skill_dispatcher.before_action(action: action, context: action_context)
        result = @primitive_executor.execute(project_root: project.path, action: routed_action)
        result = @skill_dispatcher.after_action(action: routed_action, result: result, context: action_context)
        @action_execution_store&.create(
          task_id: task.id,
          action_id: result.action_id,
          action_type: result.action_type,
          status: result.status,
          stdout: result.stdout,
          stderr: result.stderr,
          error_message: result.error_message
        )
        results << result

        next if result.status == "ok"
        next if action["on_failure"] == "continue"

        raise RuntimeError, "action_failed id=#{result.action_id} type=#{result.action_type}: #{result.error_message}"
      end
      results
    end

    def pause_workstream(project:, workstream:, reason:)
      unresolved = unresolved_questions_for(workstream.id)
      @alignment_interruption_store&.upsert(
        workstream_id: workstream.id,
        interruption_type: "pause",
        reason: reason,
        previous_state: workstream.state,
        open_question_count: unresolved,
        risk_acknowledged: true,
        open_branch_snapshot: workstream.branch
      )
      updated_ws = update_workstream_state_checked(workstream: workstream, next_state: "suspended")
      task = @task_store.create(workstream_id: updated_ws.id, description: "pause workstream: #{reason}", status: "suspended")
      FlowResult.new(project: project, workstream: updated_ws, task: task, alignment: nil, functional_spec_path: nil, technical_spec_path: nil, action_results: [])
    end

    def stop_workstream(project:, workstream:, reason:)
      unresolved = unresolved_questions_for(workstream.id)
      @alignment_interruption_store&.upsert(
        workstream_id: workstream.id,
        interruption_type: "stop",
        reason: reason,
        previous_state: workstream.state,
        open_question_count: unresolved,
        risk_acknowledged: false,
        open_branch_snapshot: workstream.branch
      )
      updated_ws = update_workstream_state_checked(workstream: workstream, next_state: "blocked")
      task = @task_store.create(workstream_id: updated_ws.id, description: "stop workstream: #{reason}", status: "blocked")
      FlowResult.new(project: project, workstream: updated_ws, task: task, alignment: nil, functional_spec_path: nil, technical_spec_path: nil, action_results: [])
    end

    def resume_workstream(project:, workstream:)
      interruption = @alignment_interruption_store&.get(workstream.id)
      target_state = interruption&.previous_state || "executing"
      if workstream.state != "suspended"
        target_state = workstream.state
      end
      updated_ws = update_workstream_state_checked(workstream: workstream, next_state: target_state)
      @alignment_interruption_store&.mark_resumed(workstream_id: workstream.id)
      task = @task_store.create(workstream_id: updated_ws.id, description: "resume workstream", status: "resumed")
      FlowResult.new(project: project, workstream: updated_ws, task: task, alignment: nil, functional_spec_path: nil, technical_spec_path: nil, action_results: [], terminal_reason: "ready")
    end

    def unresolved_questions_for(workstream_id)
      session = @alignment_store.get(workstream_id)
      return 0 unless session
      return 0 if session.pending_question.nil?

      [session.unresolved_count.to_i, 1].max
    end

    def finalize_ready_plan(project:, workstream:, session:, terminal_reason:)
      workstream = update_plan_workstream_state_checked(workstream: workstream, next_state: "ready")
      task = @task_store.create(workstream_id: workstream.id, description: "alignment complete", status: "done")
      turns = @alignment_store.turns(workstream.id)
      artifacts = @plan_spec_store&.generate(project: project, workstream: workstream, turns: turns)
      FlowResult.new(
        project: project,
        workstream: workstream,
        task: task,
        alignment: session,
        functional_spec_path: artifacts&.functional_spec_path,
        technical_spec_path: artifacts&.technical_spec_path,
        action_results: [],
        terminal_reason: terminal_reason
      )
    end

    def update_workstream_state_checked(workstream:, next_state:)
      RuntimeStateContract.assert_transition!(from: workstream.state, to: next_state)
      @workstream_store.update_state(workstream.id, next_state)
    end
  end
end
