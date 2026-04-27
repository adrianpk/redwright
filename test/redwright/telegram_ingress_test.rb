# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/telegram_ingress"

class TelegramIngressTest < Minitest::Test
  FakeClient = Struct.new(:updates) do
    def get_updates(offset:, timeout_seconds:)
      raise "unexpected timeout" unless timeout_seconds == 2
      return updates if offset.nil?

      updates.select { |u| u["update_id"] >= offset }
    end
  end

  def test_maps_allowed_text_messages_to_canonical_events
    client = FakeClient.new(
      [
        {
          "update_id" => 10,
          "message" => {
            "chat" => { "id" => 101 },
            "from" => { "id" => 9001, "username" => "adrian" },
            "text" => "build feature"
          }
        },
        {
          "update_id" => 11,
          "message" => {
            "chat" => { "id" => 999 },
            "from" => { "id" => 9002, "username" => "other" },
            "text" => "should be filtered"
          }
        }
      ]
    )
    ingress = Redwright::TelegramIngress.new(client: client, allowed_chat_ids: [101])

    result = ingress.poll(offset: nil, timeout_seconds: 2)

    assert_equal(12, result.next_offset)
    assert_equal(1, result.events.size)
    event = result.events.first
    assert_equal(10, event.update_id)
    assert_equal(101, event.chat_id)
    assert_equal(9001, event.user_id)
    assert_equal("adrian", event.username)
    assert_equal("build feature", event.text)
  end

  def test_ignores_non_text_updates_and_advances_offset
    client = FakeClient.new(
      [
        { "update_id" => 20, "message" => { "chat" => { "id" => 1 } } },
        { "update_id" => 21, "edited_message" => { "text" => "skip" } }
      ]
    )
    ingress = Redwright::TelegramIngress.new(client: client, allowed_chat_ids: [])

    result = ingress.poll(offset: nil, timeout_seconds: 2)

    assert_equal([], result.events)
    assert_equal(22, result.next_offset)
  end
end
