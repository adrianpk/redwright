# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/runtime_observability_envelope"

class RuntimeObservabilityEnvelopeTest < Minitest::Test
  def test_build_for_interactive_runtime
    envelope = Redwright::RuntimeObservabilityEnvelope.new.build(
      runtime: "interactive",
      event: "ingress_received",
      trace_id: "trc-1",
      payload: { "chat_id" => 44 }
    )

    assert_equal("interactive", envelope["runtime"])
    assert_equal("ingress_received", envelope["event"])
    assert_equal("trc-1", envelope["trace_id"])
    assert_equal(44, envelope.dig("payload", "chat_id"))
  end

  def test_build_for_factory_runtime
    envelope = Redwright::RuntimeObservabilityEnvelope.new.build(
      runtime: "factory",
      event: "ticket_dispatched",
      trace_id: "trc-2",
      payload: { "ticket_id" => "RW-42" }
    )

    assert_equal("factory", envelope["runtime"])
    assert_equal("ticket_dispatched", envelope["event"])
    assert_equal("RW-42", envelope.dig("payload", "ticket_id"))
  end

  def test_rejects_unknown_runtime
    err = assert_raises(ArgumentError) do
      Redwright::RuntimeObservabilityEnvelope.new.build(
        runtime: "other",
        event: "x",
        trace_id: "trc-3"
      )
    end

    assert_equal("unsupported runtime: other", err.message)
  end
end
