# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/workstream_store"
require "redwright/alignment_interruption_store"

class AlignmentInterruptionStoreTest < Minitest::Test
  def test_persist_and_resume_interruption_record
    Dir.mktmpdir("redwright-interruption-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        store = Redwright::AlignmentInterruptionStore.new(bootstrap.db_path)

        project = projects.register(path: "#{dir}/apps/core", aliases: ["rw"])
        ws = workstreams.create(project_id: project.id, intent: "plan", state: "waiting_user", branch: "feat/x")

        record = store.upsert(
          workstream_id: ws.id,
          interruption_type: "pause",
          reason: "pause for review",
          previous_state: ws.state,
          open_question_count: 2,
          risk_acknowledged: true,
          open_branch_snapshot: ws.branch
        )
        assert_equal("pause", record.interruption_type)
        assert_equal("waiting_user", record.previous_state)
        assert_equal(2, record.open_question_count)
        assert(record.risk_acknowledged)

        resumed = store.mark_resumed(workstream_id: ws.id)
        refute_nil(resumed.resumed_at)
      end
    end
  end
end
