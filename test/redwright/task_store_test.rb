# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/workstream_store"
require "redwright/task_store"

class TaskStoreTest < Minitest::Test
  def test_create_and_list_tasks_for_workstream
    Dir.mktmpdir("redwright-task-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        tasks = Redwright::TaskStore.new(bootstrap.db_path)

        project = projects.register(path: "#{dir}/apps/core", aliases: ["rw"])
        ws = workstreams.create(project_id: project.id, intent: "plan")
        task = tasks.create(workstream_id: ws.id, description: "draft functional spec", status: "pending")

        assert_equal(ws.id, task.workstream_id)
        assert_equal("draft functional spec", task.description)

        listed = tasks.list(workstream_id: ws.id)
        assert_equal(1, listed.size)
        assert_equal(task.id, listed.first.id)
      end
    end
  end
end
