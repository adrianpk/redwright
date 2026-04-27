# frozen_string_literal: true

require "yaml"
require "pathname"
require_relative "paths"

module Redwright
  AppConfig = Struct.new(:runtime, :telegram, :paths, :models, keyword_init: true)
  RuntimeConfig = Struct.new(:loop_interval_ms, :blocked_retry_attempts, keyword_init: true)
  TelegramConfig = Struct.new(:bot_token, :poll_interval_seconds, :allowed_chat_ids, keyword_init: true)
  PathsConfig = Struct.new(:default_projects_root, keyword_init: true)
  ModelCandidate = Struct.new(:provider, :name, keyword_init: true)
  ModelRoleConfig = Struct.new(:candidates, keyword_init: true)
  ModelsConfig = Struct.new(:coding, :non_coding, keyword_init: true)

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
      models = fetch_hash(raw, "models")

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
          default_projects_root: normalize_path_root(required_string(paths, "default_projects_root"))
        ),
        models: ModelsConfig.new(
          coding: parse_model_role(models, "coding"),
          non_coding: parse_model_role(models, "non_coding")
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

    def required_string(map, key, label: key)
      value = map[key]
      raise ArgumentError, "missing config key: #{label}" if value.nil?
      raise ArgumentError, "invalid config key: #{label} must be a non-empty string" unless value.is_a?(String) && !value.strip.empty?

      resolve_env_reference(value, label)
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

    def parse_model_role(models, key)
      raw = models[key]
      raise ArgumentError, "missing config key: models.#{key}" if raw.nil?

      candidates = case raw
                   when Hash
                     [parse_model_candidate(raw, "models.#{key}")]
                   when Array
                     raise ArgumentError, "invalid config key: models.#{key} must contain at least one candidate" if raw.empty?

                     raw.each_with_index.map do |value, index|
                       raise ArgumentError, "invalid config key: models.#{key}[#{index}] must be a mapping" unless value.is_a?(Hash)

                       parse_model_candidate(value, "models.#{key}[#{index}]")
                     end
                   else
                     raise ArgumentError, "invalid config key: models.#{key} must be a mapping or an array"
                   end

      ModelRoleConfig.new(candidates: candidates)
    end

    def parse_model_candidate(candidate, prefix)
      ModelCandidate.new(
        provider: required_string(candidate, "provider", label: "#{prefix}.provider"),
        name: required_string(candidate, "name", label: "#{prefix}.name")
      )
    end

    def normalize_path_root(value)
      base = Paths.new(mode: @mode, pwd: @pwd, home: @home).root
      raw = value.strip

      if raw.start_with?("~/")
        return File.expand_path(raw.sub("~/", ""), base)
      end

      return File.expand_path(raw) if Pathname.new(raw).absolute?

      File.expand_path(raw, base)
    end

    def integer_value(value, key)
      Integer(value)
    rescue ArgumentError, TypeError
      raise ArgumentError, "invalid config key: #{key} must be an integer"
    end

    def resolve_env_reference(value, label)
      raw = value.strip
      match = raw.match(/\A\$\{([A-Z0-9_]+)\}\z/)
      return raw unless match

      env_key = match[1]
      env_value = ENV.fetch(env_key, "").strip
      raise ArgumentError, "missing env var: #{env_key} (referenced by #{label})" if env_value.empty?

      env_value
    end
  end
end
