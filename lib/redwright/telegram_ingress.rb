# frozen_string_literal: true

module Redwright
  TelegramEvent = Struct.new(:update_id, :chat_id, :user_id, :username, :text, keyword_init: true)
  TelegramPollResult = Struct.new(:events, :next_offset, keyword_init: true)

  class TelegramIngress
    def initialize(client:, allowed_chat_ids:)
      @client = client
      @allowed_chat_ids = allowed_chat_ids
    end

    def poll(offset: nil, timeout_seconds:)
      updates = @client.get_updates(offset: offset, timeout_seconds: timeout_seconds)
      next_offset = offset
      events = []

      updates.each do |update|
        update_id = update["update_id"]
        next_offset = [next_offset, update_id.to_i + 1].compact.max

        message = update["message"]
        next unless message.is_a?(Hash)

        text = message["text"]
        next unless text.is_a?(String) && !text.strip.empty?

        chat = message["chat"]
        from = message["from"]
        next unless chat.is_a?(Hash)

        chat_id = integer_or_nil(chat["id"])
        next if chat_id.nil?
        next unless allowed_chat?(chat_id)

        events << TelegramEvent.new(
          update_id: update_id.to_i,
          chat_id: chat_id,
          user_id: integer_or_nil(from&.dig("id")),
          username: from&.dig("username"),
          text: text
        )
      end

      TelegramPollResult.new(events: events, next_offset: next_offset)
    end

    private

    def allowed_chat?(chat_id)
      return true if @allowed_chat_ids.nil? || @allowed_chat_ids.empty?

      @allowed_chat_ids.include?(chat_id)
    end

    def integer_or_nil(value)
      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
