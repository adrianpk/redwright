# frozen_string_literal: true

require "json"

module Redwright
  module CodexProof
    class InputPacket
      SCHEMA_VERSION = 1
      REQUIRED_STRING_FIELDS = %w[
        repository_url
        result_branch
        task_prompt
        validation_command
        output_directory
      ].freeze

      attr_reader :data

      def self.from_json_file(path)
        new(JSON.parse(File.read(path)))
      end

      def initialize(data)
        @data = normalize(data)
      end

      def valid?
        errors.empty?
      end

      def errors
        validation_errors = []
        validation_errors << "schema_version_unsupported" unless data["schema_version"] == SCHEMA_VERSION

        REQUIRED_STRING_FIELDS.each do |field|
          validation_errors << "#{field}_required" if data[field].to_s.strip.empty?
        end

        unless data["remote_push_policy"].is_a?(Hash)
          validation_errors << "remote_push_policy_required"
        end

        if data.dig("remote_push_policy", "enabled") != true
          validation_errors << "remote_push_policy_enabled_required"
        end

        if data["task_prompt"].to_s.strip.length < 40
          validation_errors << "task_prompt_too_short"
        end

        validation_errors
      end

      def to_h
        data.dup
      end

      private

      def normalize(raw_data)
        source = raw_data.is_a?(Hash) ? raw_data : {}
        {
          "schema_version" => integer_or_nil(source["schema_version"]),
          "repository_url" => source["repository_url"].to_s.strip,
          "result_branch" => source["result_branch"].to_s.strip,
          "task_prompt" => source["task_prompt"].to_s.strip,
          "validation_command" => source["validation_command"].to_s.strip,
          "output_directory" => source["output_directory"].to_s.strip,
          "remote_push_policy" => normalize_push_policy(source["remote_push_policy"])
        }
      end

      def integer_or_nil(value)
        Integer(value)
      rescue ArgumentError, TypeError
        nil
      end

      def normalize_push_policy(policy)
        return {} unless policy.is_a?(Hash)

        {
          "enabled" => policy["enabled"] == true,
          "remote" => policy.fetch("remote", "origin").to_s.strip,
          "branch" => policy.fetch("branch", "").to_s.strip
        }
      end
    end
  end
end
