# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/workstream_store"
require "redwright/task_store"
require "redwright/action_execution_store"
require "redwright/trace"

class ActionExecutionStoreTest < Minitest::Test
  def test_create_and_list_by_task
    Dir.mktmpdir("redwright-action-exec-store-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        tasks = Redwright::TaskStore.new(bootstrap.db_path)
        store = Redwright::ActionExecutionStore.new(bootstrap.db_path)

        project = projects.register(path: "#{dir}/apps/core", aliases: ["rw"])
        ws = workstreams.create(project_id: project.id, intent: "change", state: "executing")
        task = tasks.create(workstream_id: ws.id, description: "do thing")

        created = store.create(
          task_id: task.id,
          action_id: "a1",
          action_type: "read_file",
          status: "ok",
          stdout: "content",
          stderr: "",
          error_message: nil
        )

        assert_equal(task.id, created.task_id)
        assert_equal("a1", created.action_id)
        assert_equal("read_file", created.action_type)
        assert_equal("ok", created.status)

        rows = store.list(task_id: task.id)
        assert_equal(1, rows.size)
        assert_equal("content", rows.first.stdout)
      end
    end
  end

  def test_list_by_trace_id
    Dir.mktmpdir("redwright-action-exec-trace-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        tasks = Redwright::TaskStore.new(bootstrap.db_path)
        store = Redwright::ActionExecutionStore.new(bootstrap.db_path)

        project = projects.register(path: "#{dir}/apps/core", aliases: ["rw"])
        ws = workstreams.create(project_id: project.id, intent: "change", state: "executing")
        task = tasks.create(workstream_id: ws.id, description: "do thing")

        Redwright::Trace.with_trace_id("trc-z1") do
          store.create(task_id: task.id, action_id: "a1", action_type: "read_file", status: "ok")
        end

        rows = store.list_by_trace_id("trc-z1")
        assert_equal(1, rows.size)
        assert_equal("a1", rows.first.action_id)
        assert_equal("trc-z1", rows.first.trace_id)
      end
    end
  end
end
