# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/app_config"

class AppConfigTest < Minitest::Test
  def test_loads_valid_config_from_dev_workspace
    Dir.mktmpdir("redwright-app-config-dev-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        File.write(File.join(bootstrap.config_dir, "config.yml"), <<~YAML)
          runtime:
            loop_interval_ms: 300
            blocked_retry_attempts: 2
          telegram:
            bot_token: "token-123"
            poll_interval_seconds: 1
            allowed_chat_ids: [111, 222]
          paths:
            default_projects_root: "#{dir}/projects"
        YAML

        config = Redwright::AppConfigLoader.new(mode: :dev).load
        assert_equal(300, config.runtime.loop_interval_ms)
        assert_equal(2, config.runtime.blocked_retry_attempts)
        assert_equal("token-123", config.telegram.bot_token)
        assert_equal(1, config.telegram.poll_interval_seconds)
        assert_equal([111, 222], config.telegram.allowed_chat_ids)
        assert_equal("#{dir}/projects", config.paths.default_projects_root)
      end
    end
  end

  def test_loads_valid_config_from_real_mode_path
    Dir.mktmpdir("redwright-app-config-real-") do |home|
      config_dir = File.join(home, ".config", "redwright")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        runtime:
          loop_interval_ms: 100
          blocked_retry_attempts: 1
        telegram:
          bot_token: "real-token"
          poll_interval_seconds: 2
          allowed_chat_ids: [1]
        paths:
          default_projects_root: "#{home}/redwright"
      YAML

      config = Redwright::AppConfigLoader.new(mode: :real, home: home).load
      assert_equal(100, config.runtime.loop_interval_ms)
      assert_equal("real-token", config.telegram.bot_token)
      assert_equal([1], config.telegram.allowed_chat_ids)
    end
  end

  def test_missing_file_fails_fast
    Dir.mktmpdir("redwright-app-config-missing-") do |dir|
      err = assert_raises(ArgumentError) { Redwright::AppConfigLoader.new(mode: :real, home: dir).load }
      assert_match("missing config file:", err.message)
    end
  end

  def test_missing_required_sections_are_rejected
    Dir.mktmpdir("redwright-app-config-sections-") do |dir|
      config_dir = File.join(dir, ".config", "redwright")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        runtime:
          loop_interval_ms: 500
          blocked_retry_attempts: 1
      YAML

      err = assert_raises(ArgumentError) { Redwright::AppConfigLoader.new(mode: :real, home: dir).load }
      assert_equal("missing config key: telegram", err.message)
    end
  end

  def test_invalid_types_are_rejected
    Dir.mktmpdir("redwright-app-config-types-") do |dir|
      config_dir = File.join(dir, ".config", "redwright")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        runtime:
          loop_interval_ms: "oops"
          blocked_retry_attempts: 1
        telegram:
          bot_token: "x"
          poll_interval_seconds: 1
          allowed_chat_ids: [1]
        paths:
          default_projects_root: "#{dir}/redwright"
      YAML

      err = assert_raises(ArgumentError) { Redwright::AppConfigLoader.new(mode: :real, home: dir).load }
      assert_equal("invalid config key: loop_interval_ms must be an integer", err.message)
    end
  end
end
