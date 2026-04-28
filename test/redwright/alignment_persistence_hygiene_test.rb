# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/workstream_store"
require "redwright/alignment_store"
require "redwright/alignment_interruption_store"
require "redwright/alignment_persistence_hygiene"

class AlignmentPersistenceHygieneTest < Minitest::Test
  def test_hygiene_repairs_interrupted_state_and_cleans_resumed_rows
    Dir.mktmpdir("redwright-hygiene-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        alignments = Redwright::AlignmentStore.new(bootstrap.db_path)
        interruptions = Redwright::AlignmentInterruptionStore.new(bootstrap.db_path)
        hygiene = Redwright::AlignmentPersistenceHygiene.new(bootstrap.db_path)

        project = projects.register(path: "#{dir}/apps/core", aliases: ["rw"])
        paused_ws = workstreams.create(project_id: project.id, intent: "plan", state: "waiting_user")
        stopped_ws = workstreams.create(project_id: project.id, intent: "plan", state: "waiting_user")

        alignments.ensure_session(paused_ws.id)
        alignments.set_pending_question(paused_ws.id, question: "Q1", unresolved_count: 1)
        interruptions.upsert(
          workstream_id: paused_ws.id,
          interruption_type: "pause",
          reason: "pause",
          previous_state: "waiting_user",
          open_question_count: 1,
          risk_acknowledged: true,
          open_branch_snapshot: nil
        )

        alignments.ensure_session(stopped_ws.id)
        interruptions.upsert(
          workstream_id: stopped_ws.id,
          interruption_type: "stop",
          reason: "stop",
          previous_state: "waiting_user",
          open_question_count: 0,
          risk_acknowledged: false,
          open_branch_snapshot: nil
        )
        interruptions.mark_resumed(workstream_id: stopped_ws.id)

        hygiene.run!

        assert_equal("suspended", workstreams.get(paused_ws.id).state)
        assert_nil(interruptions.get(stopped_ws.id))
      end
    end
  end
end
