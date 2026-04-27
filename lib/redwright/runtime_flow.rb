# frozen_string_literal: true

module Redwright
  FlowResult = Struct.new(:project, :workstream, :task, keyword_init: true)

  class RuntimeFlow
    def initialize(project_store:, workstream_store:, task_store:)
      @project_store = project_store
      @workstream_store = workstream_store
      @task_store = task_store
    end

    def process(project_ref:, intent:, message:, workstream_id: nil)
      project = @project_store.resolve(project_ref)
      raise ArgumentError, "project not found" unless project

      @project_store.mark_active(project.id)

      workstream = if workstream_id && !workstream_id.empty?
                     existing = @workstream_store.get(workstream_id)
                     raise ArgumentError, "workstream not found" unless existing
                    raise ArgumentError, "workstream does not belong to project" unless existing.project_id == project.id

                     existing
                   else
                     @workstream_store.create(project_id: project.id, intent: intent, state: "executing")
                   end

      task = @task_store.create(workstream_id: workstream.id, description: message, status: "pending")
      FlowResult.new(project: project, workstream: workstream, task: task)
    end
  end
end
