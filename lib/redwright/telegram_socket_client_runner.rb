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
      @out.puts("telegram socket-client poll events=#{poll.events.size} cursor=#{@cursor.inspect}")
      poll.events.each do |event|
        session_id = "#{@session_prefix}-#{event.chat_id}"
        project_ref = inferred_project_ref(event.text)
        @out.puts("telegram socket-client event chat=#{event.chat_id} session=#{session_id} project_ref=#{project_ref.inspect} text=#{event.text.to_s[0, 120].inspect}")
        begin
          subscribe_response = client.request(type: "subscribe", session_id: session_id, payload: { "channel" => "telegram" })
          @out.puts("telegram socket-client subscribe status=#{subscribe_response.dig('payload', 'status').inspect}")

          response = client.request(
            type: "send",
            session_id: session_id,
            payload: {
              "channel" => "telegram",
              "project_ref" => project_ref,
              "intent" => "change",
              "message" => event.text.to_s,
              "actions" => []
            }
          )
          status = response.dig("payload", "status")
          message = response.dig("payload", "message")
          code = response.dig("payload", "code")
          type = response["type"].to_s
          @out.puts("telegram socket-client send status=#{status.inspect} message=#{message.inspect}")

          if type == "error"
            @ingress_port.send_message(chat_id: event.chat_id, text: "status=error code=#{code} message=#{message}")
          else
            @ingress_port.send_message(chat_id: event.chat_id, text: "status=#{status}")
          end
          @out.puts("telegram socket-client processed chat=#{event.chat_id}")
        rescue StandardError => e
          @out.puts("telegram socket-client event error chat=#{event.chat_id}: #{e.class}: #{e.message}")
        end
      end
    rescue StandardError => e
      @out.puts("telegram socket-client poll error: #{e.class}: #{e.message}")
    end

    private

    def inferred_project_ref(text)
      raw = text.to_s.strip
      return "rw" if raw.empty?

      slash_match = raw.match(%r{\A/project\s+(?:switch|new)\s+([a-zA-Z0-9._\-]+)}i)
      return "rw" if slash_match

      return "rw" if raw.start_with?("/")

      explicit = raw.match(/(?:\A|\s)project[:=]([a-zA-Z0-9._\-]+)/i)
      return explicit[1].to_s if explicit

      raw.split(/\s+/).first.to_s
    end
  end
end
