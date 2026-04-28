# frozen_string_literal: true

require "tmpdir"
require "stringio"
require "socket"
require "timeout"
require "json"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright"
require "redwright/bootstrap"

class ServerCliTest < Minitest::Test
  def test_server_run_once_acquires_and_releases_lock
    Dir.mktmpdir("redwright-server-cli-") do |dir|
      Dir.chdir(dir) do
        out = StringIO.new
        err = StringIO.new
        socket_path = File.join(dir, "_workspace", "redwright", "rw.sock")
        code = nil
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_path = File.join(bootstrap.projects_root, "alpha")
        Dir.mkdir(project_path)
        Redwright::ProjectStore.new(bootstrap.db_path).register(path: project_path, aliases: ["alpha"])
        worker = Thread.new do
          code = Redwright::CLI.new(["server", "run", "--dev", "--once"], out: out, err: err).run
        end
        Timeout.timeout(2) { sleep(0.01) until File.exist?(socket_path) }
        client = UNIXSocket.new(socket_path)
        client.write(
          JSON.generate(
            {
              type: "send",
              session_id: "cli-test",
              payload: {
                channel: "test",
                project_ref: "alpha",
                intent: "change",
                message: "create readme",
                actions: [
                  {
                    id: "w1",
                    type: "write_file",
                    args: { path: "README.md", content: "ok\n" },
                    requires_confirmation: false,
                    timeout_ms: 10_000,
                    on_failure: "abort"
                  }
                ]
              }
            }
          ) + "\n"
        )
        response = JSON.parse(client.gets)
        worker.join(2)

        assert_equal(0, code)
        assert_equal("ack", response["type"])
        assert_equal("ok", response.dig("payload", "status"))
        assert_equal("", err.string)
        assert_match("server starting", out.string)
        assert_match("server stopped", out.string)

        state_dir = File.join(dir, "_workspace", "redwright")
        assert_equal(false, File.exist?(File.join(state_dir, "runtime.lock")))
        assert_equal(false, File.exist?(socket_path))
        assert_equal(true, File.file?(File.join(project_path, "README.md")))
      ensure
        client&.close
      end
    end
  end

  def test_server_status_reports_stopped_without_lock
    Dir.mktmpdir("redwright-server-cli-status-") do |dir|
      Dir.chdir(dir) do
        out = StringIO.new
        err = StringIO.new
        code = Redwright::CLI.new(["server", "status", "--dev"], out: out, err: err).run

        assert_equal(0, code)
        assert_equal("", err.string)
        assert_match("status: stopped", out.string)
      end
    end
  end

  def test_server_ping_reports_no_server_when_not_running
    Dir.mktmpdir("redwright-server-cli-ping-") do |dir|
      Dir.chdir(dir) do
        out = StringIO.new
        err = StringIO.new
        code = Redwright::CLI.new(["server", "ping", "--dev"], out: out, err: err).run

        assert_equal(2, code)
        assert_equal("", err.string)
        assert_match("no_server", out.string)
      end
    end
  end
end
