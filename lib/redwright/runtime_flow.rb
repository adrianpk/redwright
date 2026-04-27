# frozen_string_literal: true

module Redwright
  FlowResult = Struct.new(:project, :workstream, :task, :alignment, keyword_init: true)

  class RuntimeFlow
    def initialize(project_store:, workstream_store:, task_store:, alignment_store:)
      @project_store = project_store
      @workstream_store = workstream_store
      @task_store = task_store
      @alignment_store = alignment_store
    end

    def process(project_ref:, intent:, message:, workstream_id: nil)
      project = @project_store.resolve(project_ref)
      raise ArgumentError, "project not found" unless project

      @project_store.mark_active(project.id)

      workstream = resolve_or_create_workstream(project: project, intent: intent, workstream_id: workstream_id)

      if intent == "plan"
        return process_plan(workstream: workstream, message: message, project: project)
      end

      task = @task_store.create(workstream_id: workstream.id, description: message, status: "pending")
      workstream = @workstream_store.update_state(workstream.id, "executing")
      FlowResult.new(project: project, workstream: workstream, task: task, alignment: nil)
    end

    private

    def resolve_or_create_workstream(project:, intent:, workstream_id:)
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

      initial_state = intent == "plan" ? "collecting_context" : "executing"
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
        return FlowResult.new(project: project, workstream: workstream, task: task, alignment: session)
      end

      session = @alignment_store.ask_next(workstream.id)
      workstream = @workstream_store.update_state(workstream.id, "waiting_user")
      task = @task_store.create(workstream_id: workstream.id, description: "alignment question: #{session.pending_question}", status: "waiting_user")
      FlowResult.new(project: project, workstream: workstream, task: task, alignment: session)
    end
  end
end
