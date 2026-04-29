# frozen_string_literal: true

require "yaml"

module Redwright
  class ProjectManifest
    SUPPORTED_SCHEMA_VERSION = 1

    ValidationResult = Struct.new(:data, :errors, keyword_init: true) do
      def valid?
        errors.empty?
      end
    end

    def parse_yaml(content)
      data = YAML.safe_load(content, permitted_classes: [], permitted_symbols: [], aliases: false)
      validate(data)
    rescue StandardError => e
      ValidationResult.new(data: {}, errors: ["invalid_yaml: #{e.message}"])
    end

    def load(path)
      return ValidationResult.new(data: {}, errors: ["manifest_not_found"]) unless File.file?(path)

      parse_yaml(File.read(path))
    end

    def validate(data)
      errors = []
      unless data.is_a?(Hash)
        return ValidationResult.new(data: {}, errors: ["manifest_must_be_object"])
      end

      schema_version = data["schema_version"]
      if !schema_version.is_a?(Integer)
        errors << "schema_version_required_integer"
      elsif schema_version != SUPPORTED_SCHEMA_VERSION
        errors << "schema_version_unsupported: #{schema_version}"
      end

      project = data["project"]
      if !project.is_a?(Hash)
        errors << "project_required_object"
      else
        %w[id name slug stack created_via created_at].each do |field|
          value = project[field]
          errors << "project_#{field}_required" unless non_empty_string?(value)
        end

        if non_empty_string?(project["created_via"]) && !%w[new clone].include?(project["created_via"])
          errors << "project_created_via_invalid"
        end
      end

      provenance = data["provenance"]
      created_via = project.is_a?(Hash) ? project["created_via"] : nil
      if created_via == "clone"
        if !provenance.is_a?(Hash)
          errors << "provenance_required_for_clone"
        elsif !non_empty_string?(provenance["remote_url"])
          errors << "provenance_remote_url_required_for_clone"
        end
      end

      ValidationResult.new(data: errors.empty? ? data : {}, errors: errors)
    end

    private

    def non_empty_string?(value)
      value.is_a?(String) && !value.strip.empty?
    end
  end
end
