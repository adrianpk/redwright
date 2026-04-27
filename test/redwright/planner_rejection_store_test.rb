# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/planner_rejection_store"

class PlannerRejectionStoreTest < Minitest::Test
  def test_create_and_get_planner_rejection
    Dir.mktmpdir("redwright-planner-rejection-store-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        store = Redwright::PlannerRejectionStore.new(bootstrap.db_path)

        record = store.create(
          project_id: "project-1",
          project_ref: "rw",
          reason: "invalid_payload:foo",
          raw_output: "{\"intent\":\"change\"}",
          user_text: "do something",
          trace_id: "trc-1"
        )

        assert_equal("project-1", record.project_id)
        assert_equal("rw", record.project_ref)
        assert_equal("invalid_payload:foo", record.reason)
        assert_equal("trc-1", record.trace_id)
        assert_equal(record.id, store.get(record.id).id)
      end
    end
  end
end
