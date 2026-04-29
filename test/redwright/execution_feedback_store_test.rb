# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/execution_feedback_store"

class ExecutionFeedbackStoreTest < Minitest::Test
  def test_create_and_list_for_trace
    Dir.mktmpdir("redwright-execution-feedback-store-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        store = Redwright::ExecutionFeedbackStore.new(bootstrap.db_path)

        store.create(
          trace_id: "trc-1",
          workstream_id: nil,
          task_id: nil,
          attempt: 1,
          failure_class: "test_failure",
          fingerprint: "fp-abc",
          details: { message: "tests failed" }
        )

        rows = store.list_for_trace("trc-1")
        assert_equal(1, rows.size)
        assert_equal("test_failure", rows.first["failure_class"])
        assert_equal("fp-abc", rows.first["fingerprint"])
        assert_equal("tests failed", rows.first.dig("details", "message"))
      end
    end
  end
end
