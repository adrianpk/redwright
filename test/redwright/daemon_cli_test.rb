# frozen_string_literal: true

require "tmpdir"
require "stringio"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright"
require "redwright/bootstrap"

class DaemonCliTest < Minitest::Test
  def test_daemon_run_once_with_no_ingress_starts_and_stops_cleanly
    Dir.mktmpdir("redwright-daemon-cli-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        File.write(File.join(bootstrap.config_dir, "config.yml"), <<~YAML)
          runtime:
            loop_interval_ms: 1
            blocked_retry_attempts: 1
          telegram:
            bot_token: "dummy-token"
            poll_interval_seconds: 1
            allowed_chat_ids: []
          paths:
            default_projects_root: "#{dir}/projects"
          models:
            coding:
              - provider: "openai"
                name: "gpt-5.2"
            non_coding:
              - provider: "openai"
                name: "gpt-5-mini"
        YAML

        out = StringIO.new
        err = StringIO.new
        code = Redwright::CLI.new(["daemon", "run", "--dev", "--once", "--ingress", "none"], out: out, err: err).run

        assert_equal(0, code)
        assert_equal("", err.string)
        assert_match("daemon starting", out.string)
        assert_match("ingress: none", out.string)
        assert_match("once: true", out.string)
        assert_match("queue_drain_mode: all", out.string)
        assert_match("daemon stopped", out.string)
      end
    end
  end

  def test_daemon_run_once_with_console_ingress_starts_and_stops_cleanly
    Dir.mktmpdir("redwright-daemon-cli-console-test-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        File.write(File.join(bootstrap.config_dir, "config.yml"), <<~YAML)
          runtime:
            loop_interval_ms: 1
            blocked_retry_attempts: 1
          telegram:
            bot_token: "dummy-token"
            poll_interval_seconds: 1
            allowed_chat_ids: []
          paths:
            default_projects_root: "#{dir}/projects"
          models:
            coding:
              - provider: "openai"
                name: "gpt-5.2"
            non_coding:
              - provider: "openai"
                name: "gpt-5-mini"
        YAML

        out = StringIO.new
        err = StringIO.new
        original_stdin = $stdin
        $stdin = StringIO.new("\n")
        code = Redwright::CLI.new(["daemon", "run", "--dev", "--once", "--ingress", "console"], out: out, err: err).run

        assert_equal(0, code)
        assert_equal("", err.string)
        assert_match("daemon starting", out.string)
        assert_match("ingress: console", out.string)
        assert_match("once: true", out.string)
        assert_match("queue_drain_mode: all", out.string)
        assert_match("daemon stopped", out.string)
      ensure
        $stdin = original_stdin
      end
    end
  end
end
