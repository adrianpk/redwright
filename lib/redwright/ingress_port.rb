# frozen_string_literal: true

module Redwright
  IngressEvent = Struct.new(
    :external_message_id,
    :external_chat_id,
    :sender_id,
    :text,
    :received_at,
    :transport,
    :username,
    keyword_init: true
  ) do
    def chat_id
      external_chat_id
    end
  end

  IngressPollResult = Struct.new(:events, :next_cursor, keyword_init: true)

  module IngressPort
    def poll(cursor: nil, timeout_seconds:)
      raise NotImplementedError
    end

    def send_message(chat_id:, text:)
      raise NotImplementedError
    end

    def send_chat_action(chat_id:, action: "typing")
      raise NotImplementedError
    end
  end
end
