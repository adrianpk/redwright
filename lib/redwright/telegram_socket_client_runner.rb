# frozen_string_literal: true

require_relative "local_ipc_client"

module Redwright
  class TelegramSocketClientRunner
    def initialize(ingress_port:, socket_path:, out:, poll_interval_seconds:, session_prefix: "telegram")
      @ingress_port = ingress_port
      @socket_path = socket_path
      @out = out
      @poll_interval_seconds = poll_interval_seconds
      @session_prefix = session_prefix
      @cursor = nil
    end

    def run_once
      client = LocalIpcClient.new(socket_path: @socket_path)
      poll = @ingress_port.poll(cursor: @cursor, timeout_seconds: @poll_interval_seconds)
      @cursor = poll.next_cursor
      poll.events.each do |event|
        session_id = "#{@session_prefix}-#{event.chat_id}"
        client.request(type: "subscribe", session_id: session_id, payload: { "channel" => "telegram" })
        response = client.request(
          type: "send",
          session_id: session_id,
          payload: {
            "channel" => "telegram",
            "project_ref" => inferred_project_ref(event.text),
            "intent" => "change",
            "message" => event.text.to_s,
            "actions" => []
          }
        )
        @ingress_port.send_message(chat_id: event.chat_id, text: "status=#{response.dig('payload', 'status')}")
        @out.puts("telegram socket-client processed chat=#{event.chat_id}")
      end
    end

    private

    def inferred_project_ref(text)
      token = text.to_s.strip.split(/\s+/).first.to_s
      token.empty? ? "project-1" : token
    end
  end
end
