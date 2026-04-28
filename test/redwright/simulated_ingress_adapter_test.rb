# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/simulated_ingress_adapter"

class SimulatedIngressAdapterTest < Minitest::Test
  def test_poll_and_send_interfaces_are_deterministic
    adapter = Redwright::SimulatedIngressAdapter.new(
      events: [
        Redwright::SimulatedIngressAdapter.event(external_message_id: 1, external_chat_id: 77, text: "hello")
      ]
    )

    poll = adapter.poll(cursor: nil, timeout_seconds: 0)
    assert_equal(1, poll.events.size)
    assert_equal(1, poll.next_cursor)
    assert_equal("simulated", poll.events.first.transport)

    adapter.send_chat_action(chat_id: 77, action: "typing")
    adapter.send_message(chat_id: 77, text: "ok")
    assert_equal(1, adapter.chat_actions.size)
    assert_equal(1, adapter.sent_messages.size)
  end
end
