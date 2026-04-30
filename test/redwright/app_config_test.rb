# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/app_config"

class AppConfigTest < Minitest::Test
  def test_loads_valid_config_from_dev_workspace_and_forces_workspace_projects_root
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
          models:
            coding:
              - provider: "openai"
                name: "gpt-5.2"
            non_coding:
              - provider: "openai"
                name: "gpt-5-mini"
        YAML

        config = Redwright::AppConfigLoader.new(mode: :dev).load
        assert_equal(300, config.runtime.loop_interval_ms)
        assert_equal(2, config.runtime.blocked_retry_attempts)
        assert_equal("all", config.runtime.queue_drain_mode)
        assert_equal("token-123", config.telegram.bot_token)
        assert_equal(1, config.telegram.poll_interval_seconds)
        assert_equal([111, 222], config.telegram.allowed_chat_ids)
        assert_equal(false, config.telegram.send_json_envelope)
        assert_equal(File.join(dir, "_workspace", "Projects"), config.paths.default_projects_root)
        assert_equal(8, config.alignment.max_turns)
        assert_equal(180, config.alignment.max_turn_seconds)
        assert_equal("openai", config.models.coding.candidates.first.provider)
        assert_equal("gpt-5-mini", config.models.non_coding.candidates.first.name)
      end
    end
  end

  def test_dev_mode_ignores_yaml_projects_root
    Dir.mktmpdir("redwright-app-config-dev-relative-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        File.write(File.join(bootstrap.config_dir, "config.yml"), <<~YAML)
          runtime:
            loop_interval_ms: 300
            blocked_retry_attempts: 2
          telegram:
            bot_token: "token-123"
            poll_interval_seconds: 1
            allowed_chat_ids: [111]
          paths:
            default_projects_root: "/tmp/ignored-by-dev-mode"
          models:
            coding:
              - provider: "openai"
                name: "gpt-5.2"
            non_coding:
              - provider: "openai"
                name: "gpt-5-mini"
        YAML

        config = Redwright::AppConfigLoader.new(mode: :dev).load
        assert_equal(File.join(dir, "_workspace", "Projects"), config.paths.default_projects_root)
      end
    end
  end

  def test_real_mode_resolves_tilde_paths_against_home
    Dir.mktmpdir("redwright-app-config-real-tilde-") do |home|
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
          default_projects_root: "~/redwright"
        models:
          coding:
            - provider: "openai"
              name: "gpt-5.2"
          non_coding:
            - provider: "openai"
              name: "gpt-5-mini"
      YAML

      config = Redwright::AppConfigLoader.new(mode: :real, home: home).load
      assert_equal(File.join(home, "redwright"), config.paths.default_projects_root)
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
        models:
          coding:
            - provider: "openai"
              name: "gpt-5.2"
          non_coding:
            - provider: "openai"
              name: "gpt-5-mini"
      YAML

      config = Redwright::AppConfigLoader.new(mode: :real, home: home).load
      assert_equal(100, config.runtime.loop_interval_ms)
      assert_equal("real-token", config.telegram.bot_token)
      assert_equal([1], config.telegram.allowed_chat_ids)
      assert_equal(false, config.telegram.send_json_envelope)
      assert_equal(File.join(home, "redwright"), config.paths.default_projects_root)
      assert_equal("gpt-5.2", config.models.coding.candidates.first.name)
    end
  end

  def test_real_mode_rejects_relative_projects_root
    Dir.mktmpdir("redwright-app-config-real-relative-") do |home|
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
          default_projects_root: "relative/projects"
        models:
          coding:
            - provider: "openai"
              name: "gpt-5.2"
          non_coding:
            - provider: "openai"
              name: "gpt-5-mini"
      YAML

      err = assert_raises(ArgumentError) { Redwright::AppConfigLoader.new(mode: :real, home: home).load }
      assert_equal("invalid config key: default_projects_root must be absolute in real mode", err.message)
    end
  end

  def test_loads_send_json_envelope_when_enabled
    Dir.mktmpdir("redwright-app-config-json-flag-") do |home|
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
          send_json_envelope: true
        paths:
          default_projects_root: "#{home}/redwright"
        models:
          coding:
            - provider: "openai"
              name: "gpt-5.2"
          non_coding:
            - provider: "openai"
              name: "gpt-5-mini"
      YAML

      config = Redwright::AppConfigLoader.new(mode: :real, home: home).load
      assert_equal(true, config.telegram.send_json_envelope)
    end
  end

  def test_loads_runtime_queue_drain_mode_when_enabled
    Dir.mktmpdir("redwright-app-config-queue-drain-") do |home|
      config_dir = File.join(home, ".config", "redwright")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        runtime:
          loop_interval_ms: 100
          blocked_retry_attempts: 1
          queue_drain_mode: one
        telegram:
          bot_token: "real-token"
          poll_interval_seconds: 2
          allowed_chat_ids: [1]
        paths:
          default_projects_root: "#{home}/redwright"
        models:
          coding:
            - provider: "openai"
              name: "gpt-5.2"
          non_coding:
            - provider: "openai"
              name: "gpt-5-mini"
      YAML

      config = Redwright::AppConfigLoader.new(mode: :real, home: home).load
      assert_equal("one", config.runtime.queue_drain_mode)
    end
  end

  def test_invalid_queue_drain_mode_is_rejected
    Dir.mktmpdir("redwright-app-config-queue-drain-invalid-") do |home|
      config_dir = File.join(home, ".config", "redwright")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        runtime:
          loop_interval_ms: 100
          blocked_retry_attempts: 1
          queue_drain_mode: invalid
        telegram:
          bot_token: "real-token"
          poll_interval_seconds: 2
          allowed_chat_ids: [1]
        paths:
          default_projects_root: "#{home}/redwright"
        models:
          coding:
            - provider: "openai"
              name: "gpt-5.2"
          non_coding:
            - provider: "openai"
              name: "gpt-5-mini"
      YAML

      err = assert_raises(ArgumentError) { Redwright::AppConfigLoader.new(mode: :real, home: home).load }
      assert_equal("invalid config key: queue_drain_mode must be one of all|one", err.message)
    end
  end

  def test_missing_file_fails_fast
    Dir.mktmpdir("redwright-app-config-missing-") do |dir|
      err = assert_raises(ArgumentError) { Redwright::AppConfigLoader.new(mode: :real, home: dir).load }
      assert_match("missing config file:", err.message)
    end
  end

  def test_non_telegram_ingress_does_not_require_bot_token
    Dir.mktmpdir("redwright-app-config-no-telegram-token-") do |home|
      config_dir = File.join(home, ".config", "redwright")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        runtime:
          loop_interval_ms: 100
          blocked_retry_attempts: 1
        telegram:
          poll_interval_seconds: 2
          allowed_chat_ids: [1]
        paths:
          default_projects_root: "#{home}/redwright"
        models:
          coding:
            - provider: "openai"
              name: "gpt-5.2"
          non_coding:
            - provider: "openai"
              name: "gpt-5-mini"
      YAML

      config = Redwright::AppConfigLoader.new(mode: :real, home: home).load(ingress: "tui")
      assert_equal("", config.telegram.bot_token)
      assert_equal(2, config.telegram.poll_interval_seconds)
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
      assert_equal("missing config key: paths", err.message)
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
        models:
          coding:
            - provider: "openai"
              name: "gpt-5.2"
          non_coding:
            - provider: "openai"
              name: "gpt-5-mini"
      YAML

      err = assert_raises(ArgumentError) { Redwright::AppConfigLoader.new(mode: :real, home: dir).load }
      assert_equal("invalid config key: loop_interval_ms must be an integer", err.message)
    end
  end

  def test_missing_models_section_is_rejected
    Dir.mktmpdir("redwright-app-config-models-missing-") do |dir|
      config_dir = File.join(dir, ".config", "redwright")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        runtime:
          loop_interval_ms: 100
          blocked_retry_attempts: 1
        telegram:
          bot_token: "x"
          poll_interval_seconds: 1
          allowed_chat_ids: [1]
        paths:
          default_projects_root: "#{dir}/redwright"
      YAML

      err = assert_raises(ArgumentError) { Redwright::AppConfigLoader.new(mode: :real, home: dir).load }
      assert_equal("missing config key: models", err.message)
    end
  end

  def test_loads_env_reference_in_yaml_string_values
    Dir.mktmpdir("redwright-app-config-env-ref-") do |dir|
      config_dir = File.join(dir, ".config", "redwright")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        runtime:
          loop_interval_ms: 100
          blocked_retry_attempts: 1
        telegram:
          bot_token: "${TEST_TELEGRAM_TOKEN}"
          poll_interval_seconds: 1
          allowed_chat_ids: [1]
        paths:
          default_projects_root: "#{dir}/redwright"
        models:
          coding:
            - provider: "openai"
              name: "gpt-5.2"
          non_coding:
            - provider: "openai"
              name: "gpt-5-mini"
      YAML

      previous = ENV["TEST_TELEGRAM_TOKEN"]
      ENV["TEST_TELEGRAM_TOKEN"] = "token-from-env"
      config = Redwright::AppConfigLoader.new(mode: :real, home: dir).load
      assert_equal("token-from-env", config.telegram.bot_token)
    ensure
      ENV["TEST_TELEGRAM_TOKEN"] = previous
    end
  end

  def test_env_reference_fails_when_missing
    Dir.mktmpdir("redwright-app-config-env-missing-") do |dir|
      config_dir = File.join(dir, ".config", "redwright")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        runtime:
          loop_interval_ms: 100
          blocked_retry_attempts: 1
        telegram:
          bot_token: "${MISSING_REDWRIGHT_TOKEN}"
          poll_interval_seconds: 1
          allowed_chat_ids: [1]
        paths:
          default_projects_root: "#{dir}/redwright"
        models:
          coding:
            - provider: "openai"
              name: "gpt-5.2"
          non_coding:
            - provider: "openai"
              name: "gpt-5-mini"
      YAML

      previous = ENV.delete("MISSING_REDWRIGHT_TOKEN")
      err = assert_raises(ArgumentError) { Redwright::AppConfigLoader.new(mode: :real, home: dir).load }
      assert_equal("missing env var: MISSING_REDWRIGHT_TOKEN (referenced by bot_token)", err.message)
    ensure
      ENV["MISSING_REDWRIGHT_TOKEN"] = previous if previous
    end
  end

  def test_loads_alignment_bounds_from_config
    Dir.mktmpdir("redwright-app-config-alignment-") do |dir|
      config_dir = File.join(dir, ".config", "redwright")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        runtime:
          loop_interval_ms: 100
          blocked_retry_attempts: 2
        telegram:
          bot_token: "x"
          poll_interval_seconds: 1
          allowed_chat_ids: [1]
        paths:
          default_projects_root: "#{dir}/projects"
        alignment:
          max_turns: 12
          max_turn_seconds: 240
        models:
          coding:
            - provider: "openai"
              name: "gpt-5.2"
          non_coding:
            - provider: "openai"
              name: "gpt-5-mini"
      YAML

      config = Redwright::AppConfigLoader.new(mode: :real, home: dir).load
      assert_equal(12, config.alignment.max_turns)
      assert_equal(240, config.alignment.max_turn_seconds)
    end
  end

  def test_loads_models_aliases
    Dir.mktmpdir("redwright-app-config-model-aliases-") do |dir|
      config_dir = File.join(dir, ".config", "redwright")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        runtime:
          loop_interval_ms: 100
          blocked_retry_attempts: 2
        telegram:
          bot_token: "x"
          poll_interval_seconds: 1
          allowed_chat_ids: [1]
        paths:
          default_projects_root: "#{dir}/projects"
        models:
          aliases:
            "openai/codex":
              provider: "openai"
              name: "gpt-5.2"
          coding:
            - provider: "openai"
              name: "openai/codex"
          non_coding:
            - provider: "openai"
              name: "gpt-5-mini"
      YAML

      config = Redwright::AppConfigLoader.new(mode: :real, home: dir).load
      alias_target = config.models.aliases.fetch("openai/codex")
      assert_equal("openai", alias_target.provider)
      assert_equal("gpt-5.2", alias_target.name)
    end
  end
end
