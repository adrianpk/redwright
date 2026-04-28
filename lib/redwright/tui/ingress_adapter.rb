# frozen_string_literal: true

require "time"
require_relative "../ingress_port"

module Redwright
  module Tui
    class IngressAdapter
      include IngressPort

      DEFAULT_CHAT_ID = 1

      def initialize(input: $stdin, shell:, local_chat_id: DEFAULT_CHAT_ID)
        @input = input
        @shell = shell
        @local_chat_id = local_chat_id
        @message_seq = 0
        @shell.enter!
      end

      def poll(cursor: nil, timeout_seconds:)
        _ = cursor
        if @input.is_a?(IO)
          ready = IO.select([@input], nil, nil, timeout_seconds.to_f)
          return IngressPollResult.new(events: [], next_cursor: @message_seq) if ready.nil?
        end

        line = @input.gets
        return IngressPollResult.new(events: [], next_cursor: @message_seq) if line.nil?

        text = line.to_s.strip
        return IngressPollResult.new(events: [], next_cursor: @message_seq) if text.empty?

        @shell.add_user_message(text)
        @message_seq += 1
        event = IngressEvent.new(
          external_message_id: @message_seq,
          external_chat_id: @local_chat_id,
          sender_id: nil,
          text: text,
          received_at: Time.now.utc.iso8601(6),
          transport: "tui",
          username: "local"
        )
        IngressPollResult.new(events: [event], next_cursor: @message_seq)
      end

      def send_message(chat_id:, text:)
        _ = chat_id
        @shell.add_runtime_message(text)
        { "ok" => true }
      end

      def send_chat_action(chat_id:, action: "typing")
        _ = chat_id
        _ = action
        { "ok" => true }
      end

      def close
        @shell.exit!
      end
    end
  end
end
