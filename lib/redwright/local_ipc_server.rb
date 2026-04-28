# frozen_string_literal: true

require "socket"
require "json"
require "fileutils"
require_relative "local_ipc_protocol"
require_relative "local_ipc_session_registry"

module Redwright
  class LocalIpcServer
    def initialize(socket_path:, dispatcher:, protocol: LocalIpcProtocol.new, session_registry: LocalIpcSessionRegistry.new)
      @socket_path = socket_path
      @dispatcher = dispatcher
      @protocol = protocol
      @session_registry = session_registry
      @server = nil
    end

    def run_once
      open_server
      client = @server.accept
      line = client.gets
      begin
        request = @protocol.decode_request(line)
        session_id = request.fetch("session_id").to_s
        channel = request.fetch("payload", {}).fetch("channel", "unknown").to_s
        subscribed = request.fetch("type").to_s == "subscribe"
        @session_registry.upsert(session_id: session_id, channel: channel, subscribed: subscribed)

        event_payload = @dispatcher.call(request)
        response = @protocol.encode_envelope(type: "ack", session_id: session_id, payload: event_payload)
        client.write(response)
      rescue ArgumentError => e
        sid = extract_session_id(line)
        response = @protocol.encode_envelope(
          type: "error",
          session_id: sid,
          payload: { "code" => "bad_request", "message" => e.message }
        )
        client.write(response)
      end
    ensure
      client&.close
    end

    def close
      @server&.close
      @server = nil
      File.delete(@socket_path) if File.exist?(@socket_path)
    end

    private

    def open_server
      return if @server

      FileUtils.mkdir_p(File.dirname(@socket_path))
      File.delete(@socket_path) if File.exist?(@socket_path)
      @server = UNIXServer.new(@socket_path)
    end

    def extract_session_id(line)
      parsed = JSON.parse(line.to_s)
      sid = parsed.fetch("session_id", "").to_s
      sid.empty? ? "unknown" : sid
    rescue StandardError
      "unknown"
    end
  end
end
