# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/workstream_store"
require "redwright/task_store"
require "redwright/task_commit_store"

class TaskCommitStoreTest < Minitest::Test
  def test_add_and_list_commits_for_task
    Dir.mktmpdir("redwright-task-commit-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        tasks = Redwright::TaskStore.new(bootstrap.db_path)
        commits = Redwright::TaskCommitStore.new(bootstrap.db_path)

        project = projects.register(path: "#{dir}/apps/core", aliases: ["rw"])
        ws = workstreams.create(project_id: project.id, intent: "change")
        task = tasks.create(workstream_id: ws.id, description: "implement runtime", status: "pending")

        commits.add(task_id: task.id, commit_sha: "abc1234")
        commits.add(task_id: task.id, commit_sha: "def5678")
        commits.add(task_id: task.id, commit_sha: "abc1234")

        rows = commits.list(task_id: task.id)
        assert_equal(2, rows.size)
        assert_equal("abc1234", rows[0][:commit_sha])
        assert_equal("def5678", rows[1][:commit_sha])
      end
    end
  end
end
