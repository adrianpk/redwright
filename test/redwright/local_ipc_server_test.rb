# frozen_string_literal: true

require "tmpdir"
require "socket"
require "timeout"
require "json"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/local_ipc_server"
require "redwright/local_ipc_session_registry"

class LocalIpcServerTest < Minitest::Test
  def test_run_once_accepts_subscribe_and_returns_ack
    Dir.mktmpdir("redwright-ipc-server-") do |dir|
      socket_path = File.join(dir, "rw.sock")
      registry = Redwright::LocalIpcSessionRegistry.new
      server = Redwright::LocalIpcServer.new(
        socket_path: socket_path,
        session_registry: registry,
        dispatcher: ->(request) { { "status" => "ok", "echo_type" => request["type"] } }
      )

      thread = Thread.new { server.run_once }
      Timeout.timeout(1) { sleep(0.01) until File.exist?(socket_path) }
      client = UNIXSocket.new(socket_path)
      client.write("{\"type\":\"subscribe\",\"session_id\":\"s-1\",\"payload\":{\"channel\":\"tui\"}}\n")
      response = client.gets
      payload = JSON.parse(response)
      assert_equal("ack", payload["type"])
      assert_equal("s-1", payload["session_id"])
      assert_equal("ok", payload.dig("payload", "status"))
      thread.join(1)
      assert_equal(1, registry.count)
    ensure
      client&.close
    end
  end

  def test_run_once_rejects_invalid_payload
    Dir.mktmpdir("redwright-ipc-server-bad-") do |dir|
      socket_path = File.join(dir, "rw.sock")
      server = Redwright::LocalIpcServer.new(
        socket_path: socket_path,
        dispatcher: ->(_request) { { "status" => "ok" } }
      )

      thread = Thread.new { server.run_once }
      Timeout.timeout(1) { sleep(0.01) until File.exist?(socket_path) }
      client = UNIXSocket.new(socket_path)
      client.write("{\"type\":\"send\",\"session_id\":\"s-2\",\"payload\":1}\n")
      response = client.gets
      payload = JSON.parse(response)
      assert_equal("error", payload["type"])
      assert_equal("bad_request", payload.dig("payload", "code"))
      thread.join(1)
    ensure
      client&.close
    end
  end
end
