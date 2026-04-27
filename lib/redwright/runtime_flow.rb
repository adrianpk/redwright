# frozen_string_literal: true

require_relative "trace"

module Redwright
  FlowResult = Struct.new(
    :project, :workstream, :task, :alignment, :functional_spec_path, :technical_spec_path, :action_results,
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
      action_execution_store: nil
    )
      @project_store = project_store
      @workstream_store = workstream_store
      @task_store = task_store
      @alignment_store = alignment_store
      @plan_spec_store = plan_spec_store
      @primitive_executor = primitive_executor
      @action_execution_store = action_execution_store
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
      Trace.with_trace_id do
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
      workstream = @workstream_store.update_state(workstream.id, "executing")
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
        action_results: action_results
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
        session = @alignment_store.answer_pending(workstream.id, message)
      end

      if session.decisions_stable
        workstream = @workstream_store.update_state(workstream.id, "ready")
        task = @task_store.create(workstream_id: workstream.id, description: "alignment complete", status: "done")
        turns = @alignment_store.turns(workstream.id)
        artifacts = @plan_spec_store&.generate(project: project, workstream: workstream, turns: turns)
        return FlowResult.new(
          project: project,
          workstream: workstream,
          task: task,
          alignment: session,
          functional_spec_path: artifacts&.functional_spec_path,
          technical_spec_path: artifacts&.technical_spec_path
        )
      end

      session = @alignment_store.ask_next(workstream.id)
      workstream = @workstream_store.update_state(workstream.id, "waiting_user")
      task = @task_store.create(workstream_id: workstream.id, description: "alignment question: #{session.pending_question}", status: "waiting_user")
      FlowResult.new(project: project, workstream: workstream, task: task, alignment: session, functional_spec_path: nil, technical_spec_path: nil)
    end

    def execute_actions(project:, task:, actions:)
      return [] if actions.nil? || actions.empty?
      raise ArgumentError, "primitive executor is not configured" unless @primitive_executor

      results = []
      actions.each do |action|
        result = @primitive_executor.execute(project_root: project.path, action: action)
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
  end
end
