# frozen_string_literal: true

require "time"
require_relative "ingress_port"

module Redwright
  class SimulatedIngressAdapter
    include IngressPort

    attr_reader :sent_messages, :chat_actions

    def initialize(events: [])
      @events = events
      @cursor = 0
      @sent_messages = []
      @chat_actions = []
    end

    def poll(cursor: nil, timeout_seconds:)
      @cursor = cursor.to_i if cursor
      remaining = @events[@cursor..] || []
      next_cursor = @cursor + remaining.size
      @cursor = next_cursor
      IngressPollResult.new(events: remaining, next_cursor: next_cursor)
    end

    def send_message(chat_id:, text:)
      @sent_messages << { chat_id: chat_id, text: text }
      { "ok" => true }
    end

    def send_chat_action(chat_id:, action: "typing")
      @chat_actions << { chat_id: chat_id, action: action }
      { "ok" => true }
    end

    def self.event(external_message_id:, external_chat_id:, text:, sender_id: nil, transport: "simulated", username: nil)
      IngressEvent.new(
        external_message_id: external_message_id,
        external_chat_id: external_chat_id,
        sender_id: sender_id,
        text: text,
        received_at: Time.now.utc.iso8601(6),
        transport: transport,
        username: username
      )
    end
  end
end
