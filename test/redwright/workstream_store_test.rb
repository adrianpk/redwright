# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/workstream_store"

class WorkstreamStoreTest < Minitest::Test
  def test_create_and_list_workstreams_for_project
    Dir.mktmpdir("redwright-workstream-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)

        project = projects.register(path: "#{dir}/apps/core", aliases: ["rw"])
        created = workstreams.create(
          project_id: project.id,
          intent: "change",
          state: "ready",
          branch: "feat/slice-6",
          worktree_path: "#{dir}/_workspace/redwright/.worktrees/ws-1"
        )

        assert_equal(project.id, created.project_id)
        assert_equal("change", created.intent)
        assert_equal("ready", created.state)

        listed = workstreams.list(project_id: project.id)
        assert_equal(1, listed.size)
        assert_equal(created.id, listed.first.id)
      end
    end
  end
end
