# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/telegram_ingress_adapter"

class TelegramIngressAdapterTest < Minitest::Test
  FakeClient = Struct.new(:updates, :messages, :actions) do
    def get_updates(offset:, timeout_seconds:)
      updates || []
    end

    def send_message(chat_id:, text:)
      self.messages ||= []
      messages << { chat_id: chat_id, text: text }
      { "ok" => true }
    end

    def send_chat_action(chat_id:, action: "typing")
      self.actions ||= []
      actions << { chat_id: chat_id, action: action }
      { "ok" => true }
    end
  end

  def test_maps_telegram_updates_to_canonical_events
    client = FakeClient.new(
      [
        {
          "update_id" => 22,
          "message" => {
            "text" => "hello",
            "chat" => { "id" => 9 },
            "from" => { "id" => 44, "username" => "adrian" }
          }
        }
      ]
    )
    adapter = Redwright::TelegramIngressAdapter.new(client: client, allowed_chat_ids: [9])

    poll = adapter.poll(cursor: nil, timeout_seconds: 1)
    assert_equal(1, poll.events.size)
    evt = poll.events.first
    assert_equal(22, evt.external_message_id)
    assert_equal(9, evt.external_chat_id)
    assert_equal(44, evt.sender_id)
    assert_equal("hello", evt.text)
    assert_equal("telegram", evt.transport)
    assert_equal(23, poll.next_cursor)
  end
end
