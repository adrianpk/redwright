# frozen_string_literal: true

require "json"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/runtime_result_envelope"

class RuntimeResultEnvelopeTest < Minitest::Test
  def test_success_envelope_structure
    envelope = Redwright::RuntimeResultEnvelope.success(
      trace_id: "trc-1",
      project_id: "p1",
      workstream_id: "ws1",
      task_id: "t1",
      state: "executing"
    )
    payload = JSON.parse(envelope.to_json_string)

    assert_equal("ok", payload["status"])
    assert_equal("trc-1", payload["trace_id"])
    assert_equal("p1", payload.dig("runtime", "project_id"))
    assert_equal("ws1", payload.dig("runtime", "workstream_id"))
    assert_equal("t1", payload.dig("runtime", "task_id"))
    assert_equal("executing", payload.dig("runtime", "state"))
  end

  def test_success_envelope_with_execution_summary
    envelope = Redwright::RuntimeResultEnvelope.success(
      trace_id: "trc-1",
      project_id: "p1",
      workstream_id: "ws1",
      task_id: "t1",
      state: "executing",
      execution: {
        total_actions: 2,
        succeeded_actions: 1,
        failed_actions: 1,
        failed_action_ids: ["a2"]
      }
    )
    payload = JSON.parse(envelope.to_json_string)

    assert_equal(2, payload.dig("runtime", "execution", "total_actions"))
    assert_equal(1, payload.dig("runtime", "execution", "succeeded_actions"))
    assert_equal(1, payload.dig("runtime", "execution", "failed_actions"))
    assert_equal(["a2"], payload.dig("runtime", "execution", "failed_action_ids"))
  end

  def test_error_envelope_structure
    envelope = Redwright::RuntimeResultEnvelope.error(trace_id: "trc-2", message: "boom")
    payload = JSON.parse(envelope.to_json_string)

    assert_equal("error", payload["status"])
    assert_equal("trc-2", payload["trace_id"])
    assert_equal("runtime_error", payload.dig("error", "code"))
    assert_equal("boom", payload.dig("error", "message"))
  end

  def test_clarify_envelope_structure
    envelope = Redwright::RuntimeResultEnvelope.clarify(trace_id: "trc-3", message: "Which project?")
    payload = JSON.parse(envelope.to_json_string)

    assert_equal("clarify", payload["status"])
    assert_equal("trc-3", payload["trace_id"])
    assert_equal("Which project?", payload.dig("clarify", "question"))
  end
end
