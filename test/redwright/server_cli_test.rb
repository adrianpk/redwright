# frozen_string_literal: true

require "tmpdir"
require "stringio"
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
        code = Redwright::CLI.new(["server", "run", "--dev", "--once"], out: out, err: err).run

        assert_equal(0, code)
        assert_equal("", err.string)
        assert_match("server starting", out.string)
        assert_match("server stopped", out.string)

        state_dir = File.join(dir, "_workspace", "redwright")
        assert_equal(false, File.exist?(File.join(state_dir, "runtime.lock")))
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
