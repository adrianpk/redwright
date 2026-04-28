# frozen_string_literal: true

require "tmpdir"
require "socket"
require "json"
require "thread"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/telegram_socket_client_runner"
require "redwright/simulated_ingress_adapter"

class TelegramSocketClientRunnerTest < Minitest::Test
  def test_telegram_socket_client_processes_event_and_replies
    Dir.mktmpdir("redwright-telegram-socket-client-") do |dir|
      socket_path = File.join(dir, "rw.sock")
      ingress = Redwright::SimulatedIngressAdapter.new(
        events: [Redwright::SimulatedIngressAdapter.event(external_message_id: 1, external_chat_id: 9, text: "alpha do work", transport: "telegram")]
      )
      out = StringIO.new
      received = Queue.new
      server = UNIXServer.new(socket_path)
      thread = Thread.new do
        2.times do
          c = server.accept
          line = c.gets
          req = JSON.parse(line)
          received << req
          c.write("{\"type\":\"ack\",\"session_id\":\"ok\",\"payload\":{\"status\":\"ok\"}}\n")
          c.close
        end
      end

      runner = Redwright::TelegramSocketClientRunner.new(
        ingress_port: ingress,
        socket_path: socket_path,
        out: out,
        poll_interval_seconds: 0
      )
      runner.run_once
      thread.join(1)

      first = received.pop
      second = received.pop
      assert_equal("subscribe", first["type"])
      assert_equal("send", second["type"])
      assert_equal("alpha", second.dig("payload", "project_ref"))
      assert_includes(ingress.sent_messages.last[:text], "status=ok")
    ensure
      server&.close
    end
  end
end
