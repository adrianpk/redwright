# frozen_string_literal: true

require "socket"
require "json"
require_relative "local_ipc_protocol"

module Redwright
  class LocalIpcClient
    def initialize(socket_path:, protocol: LocalIpcProtocol.new)
      @socket_path = socket_path
      @protocol = protocol
    end

    def request(type:, session_id:, payload:)
      line = JSON.generate(
        {
          "type" => type.to_s,
          "session_id" => session_id.to_s,
          "payload" => payload
        }
      ) + "\n"
      socket = UNIXSocket.new(@socket_path)
      socket.write(line)
      response_line = socket.gets
      raise RuntimeError, "ipc_no_response" if response_line.nil?

      JSON.parse(response_line)
    ensure
      socket&.close
    end
  end
end
