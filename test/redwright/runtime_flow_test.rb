# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/workstream_store"
require "redwright/task_store"
require "redwright/runtime_flow"

class RuntimeFlowTest < Minitest::Test
  def test_process_creates_workstream_and_task_for_project
    Dir.mktmpdir("redwright-flow-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)

        project = project_store.register(path: "#{dir}/apps/core", aliases: ["rw"])
        flow = Redwright::RuntimeFlow.new(project_store: project_store, workstream_store: ws_store, task_store: task_store)

        result = flow.process(project_ref: "rw", intent: "change", message: "implement init")

        assert_equal(project.id, result.project.id)
        assert_equal(project.id, result.workstream.project_id)
        assert_equal("change", result.workstream.intent)
        assert_equal(result.workstream.id, result.task.workstream_id)
        assert_equal("implement init", result.task.description)
      end
    end
  end

  def test_process_with_existing_workstream_reuses_it
    Dir.mktmpdir("redwright-flow-reuse-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)

        project = project_store.register(path: "#{dir}/apps/core", aliases: ["rw"])
        ws = ws_store.create(project_id: project.id, intent: "investigate", state: "executing")

        flow = Redwright::RuntimeFlow.new(project_store: project_store, workstream_store: ws_store, task_store: task_store)
        result = flow.process(project_ref: "rw", intent: "change", message: "continue analysis", workstream_id: ws.id)

        assert_equal(ws.id, result.workstream.id)
        assert_equal("continue analysis", result.task.description)
        assert_equal(1, ws_store.list(project_id: project.id).size)
      end
    end
  end
end
