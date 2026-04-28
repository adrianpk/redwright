# frozen_string_literal: true

require_relative "shell"
require_relative "../local_ipc_client"

module Redwright
  module Tui
    class SocketClientRunner
      def initialize(input:, output:, socket_path:, session_id: "tui-local")
        @input = input
        @output = output
        @socket_path = socket_path
        @session_id = session_id
      end

      def run_once
        shell = Shell.new(output: @output)
        shell.enter!
        client = LocalIpcClient.new(socket_path: @socket_path)
        client.request(type: "subscribe", session_id: @session_id, payload: { "channel" => "tui" })

        text = @input.gets.to_s.strip
        return if text.empty?

        shell.add_user_message(text)
        response = client.request(
          type: "send",
          session_id: @session_id,
          payload: {
            "channel" => "tui",
            "project_ref" => inferred_project_ref(text),
            "intent" => "change",
            "message" => text,
            "actions" => []
          }
        )
        shell.add_runtime_message("status=#{response.dig('payload', 'status')}")
      ensure
        shell&.exit!
      end

      private

      def inferred_project_ref(text)
        token = text.to_s.strip.split(/\s+/).first.to_s
        token.empty? ? "project-1" : token
      end
    end
  end
end
