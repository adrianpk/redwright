# frozen_string_literal: true

require "fileutils"
require "json"
require "time"

module Redwright
  class LlmTraceFileWriter
    def initialize(config:, env: ENV)
      @config = config
      @env = env
    end

    def enabled?
      @config && @config.enabled == true
    end

    def write(event)
      return unless enabled?

      path = File.expand_path(@config.path.to_s)
      FileUtils.mkdir_p(File.dirname(path))
      line = JSON.generate(redact_event(normalize_event(event))) + "\n"
      rotate_if_needed(path, line.bytesize)
      File.open(path, "a") { |file| file.write(line) }
    end

    private

    def normalize_event(event)
      normalized = {}
      event.each do |key, value|
        next if value.nil?

        normalized[key.to_s] = value
      end
      normalized["timestamp"] ||= Time.now.utc.iso8601(3)
      normalized
    end

    def redact_event(event)
      event.each_with_object({}) do |(key, value), acc|
        acc[key] = redact_value(key, value)
      end
    end

    def redact_value(key, value)
      case value
      when String
        redact_string(value, field_name: key.to_s)
      when Array
        value.map { |entry| redact_value(key, entry) }
      when Hash
        value.each_with_object({}) do |(child_key, child_value), acc|
          acc[child_key] = redact_value(child_key, child_value)
        end
      else
        value
      end
    end

    def redact_string(value, field_name:)
      redacted = value.dup
      redacted.gsub!(/(Authorization\s*[:=]\s*["']?Bearer\s+)([^\s"',]+)/i, '\1[REDACTED]')
      redacted.gsub!(/(Bearer\s+)([A-Za-z0-9._\-]+)/, '\1[REDACTED]')
      if secret_like_field?(field_name)
        redacted = "[REDACTED]"
      else
        secret_env_values.each do |secret|
          redacted.gsub!(secret, "[REDACTED]") unless secret.empty?
        end
      end
      redacted
    end

    def secret_like_field?(field_name)
      field_name.match?(/token|secret|password|authorization|api[_-]?key/i)
    end

    def secret_env_values
      @secret_env_values ||= @env.each_with_object([]) do |(key, value), acc|
        next unless key.to_s.match?(/token|secret|password|authorization|api[_-]?key/i)
        next unless value.is_a?(String)
        next if value.strip.empty?

        acc << value
      end
    end

    def rotate_if_needed(path, incoming_bytes)
      return unless File.file?(path)
      return if File.size(path) + incoming_bytes <= @config.max_bytes.to_i

      keep = @config.keep_files.to_i
      File.delete("#{path}.#{keep}") if keep >= 1 && File.exist?("#{path}.#{keep}")
      keep.downto(2) do |index|
        from = "#{path}.#{index - 1}"
        to = "#{path}.#{index}"
        File.rename(from, to) if File.exist?(from)
      end
      File.rename(path, "#{path}.1")
    end
  end
end
