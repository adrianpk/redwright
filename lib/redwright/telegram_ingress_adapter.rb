# frozen_string_literal: true

require "time"
require_relative "ingress_port"
require_relative "telegram_ingress"

module Redwright
  class TelegramIngressAdapter
    include IngressPort

    def initialize(client:, allowed_chat_ids:)
      @client = client
      @ingress = TelegramIngress.new(client: client, allowed_chat_ids: allowed_chat_ids)
    end

    def poll(cursor: nil, timeout_seconds:)
      result = @ingress.poll(offset: cursor, timeout_seconds: timeout_seconds)
      events = result.events.map do |event|
        IngressEvent.new(
          external_message_id: event.update_id,
          external_chat_id: event.chat_id,
          sender_id: event.user_id,
          text: event.text,
          received_at: Time.now.utc.iso8601(6),
          transport: "telegram",
          username: event.username
        )
      end
      IngressPollResult.new(events: events, next_cursor: result.next_offset)
    end

    def send_message(chat_id:, text:)
      @client.send_message(chat_id: chat_id, text: text)
    end

    def send_chat_action(chat_id:, action: "typing")
      @client.send_chat_action(chat_id: chat_id, action: action)
    end
  end
end
