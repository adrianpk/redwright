# frozen_string_literal: true

require "tmpdir"
require "socket"
require "json"
require "thread"
require "stringio"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/tui/socket_client_runner"

class TuiSocketClientRunnerTest < Minitest::Test
  def test_tui_socket_client_sends_subscribe_and_send_requests
    Dir.mktmpdir("redwright-tui-socket-client-") do |dir|
      socket_path = File.join(dir, "rw.sock")
      received = Queue.new
      server = UNIXServer.new(socket_path)
      thread = Thread.new do
        2.times do
          c = server.accept
          line = c.gets
          received << JSON.parse(line)
          c.write("{\"type\":\"ack\",\"session_id\":\"tui-local\",\"payload\":{\"status\":\"ok\"}}\n")
          c.close
        end
      end

      out = StringIO.new
      runner = Redwright::Tui::SocketClientRunner.new(
        input: StringIO.new("alpha build app\n"),
        output: out,
        socket_path: socket_path
      )
      runner.run_once
      thread.join(1)

      first = received.pop
      second = received.pop
      assert_equal("subscribe", first["type"])
      assert_equal("send", second["type"])
      assert_equal("alpha", second.dig("payload", "project_ref"))
    ensure
      server&.close
    end
  end
end
