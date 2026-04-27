# frozen_string_literal: true

require "yaml"
require_relative "paths"

module Redwright
  AppConfig = Struct.new(:runtime, :telegram, :paths, keyword_init: true)
  RuntimeConfig = Struct.new(:loop_interval_ms, :blocked_retry_attempts, keyword_init: true)
  TelegramConfig = Struct.new(:bot_token, :poll_interval_seconds, :allowed_chat_ids, keyword_init: true)
  PathsConfig = Struct.new(:default_projects_root, keyword_init: true)

  class AppConfigLoader
    def initialize(mode: :dev, pwd: Dir.pwd, home: Dir.home)
      @mode = mode
      @pwd = pwd
      @home = home
    end

    def load
      config_path = File.join(Paths.new(mode: @mode, pwd: @pwd, home: @home).config_dir, "config.yml")
      raise ArgumentError, "missing config file: #{config_path}" unless File.file?(config_path)

      raw = YAML.safe_load(File.read(config_path), permitted_classes: [], permitted_symbols: [], aliases: false)
      raise ArgumentError, "invalid config: root must be a mapping" unless raw.is_a?(Hash)

      runtime = fetch_hash(raw, "runtime")
      telegram = fetch_hash(raw, "telegram")
      paths = fetch_hash(raw, "paths")

      AppConfig.new(
        runtime: RuntimeConfig.new(
          loop_interval_ms: positive_integer(runtime, "loop_interval_ms"),
          blocked_retry_attempts: positive_integer(runtime, "blocked_retry_attempts")
        ),
        telegram: TelegramConfig.new(
          bot_token: required_string(telegram, "bot_token"),
          poll_interval_seconds: positive_integer(telegram, "poll_interval_seconds"),
          allowed_chat_ids: required_array(telegram, "allowed_chat_ids").map { |id| integer_value(id, "allowed_chat_ids[]") }
        ),
        paths: PathsConfig.new(
          default_projects_root: required_string(paths, "default_projects_root")
        )
      )
    rescue Psych::SyntaxError => e
      raise ArgumentError, "invalid config yaml: #{e.message}"
    end

    private

    def fetch_hash(raw, key)
      value = raw[key]
      raise ArgumentError, "missing config key: #{key}" if value.nil?
      raise ArgumentError, "invalid config key: #{key} must be a mapping" unless value.is_a?(Hash)

      value
    end

    def required_string(map, key)
      value = map[key]
      raise ArgumentError, "missing config key: #{key}" if value.nil?
      raise ArgumentError, "invalid config key: #{key} must be a non-empty string" unless value.is_a?(String) && !value.strip.empty?

      value
    end

    def required_array(map, key)
      value = map[key]
      raise ArgumentError, "missing config key: #{key}" if value.nil?
      raise ArgumentError, "invalid config key: #{key} must be an array" unless value.is_a?(Array)

      value
    end

    def positive_integer(map, key)
      value = map[key]
      raise ArgumentError, "missing config key: #{key}" if value.nil?

      int = integer_value(value, key)
      raise ArgumentError, "invalid config key: #{key} must be >= 1" if int < 1

      int
    end

    def integer_value(value, key)
      Integer(value)
    rescue ArgumentError, TypeError
      raise ArgumentError, "invalid config key: #{key} must be an integer"
    end
  end
end
