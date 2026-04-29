# frozen_string_literal: true

require "yaml"
require_relative "skill_manifest"

module Redwright
  class SkillLoader
    def initialize(base_dir:)
      @base_dir = base_dir
    end

    def load_all
      manifest_paths.filter_map { |path| load_path(path) }
    end

    def load(skill_id)
      return nil if skill_id.to_s.strip.empty?

      path = manifest_paths.find do |p|
        data = read_yaml(p)
        data["id"].to_s == skill_id.to_s
      end
      return nil unless path

      load_path(path)
    end

    private

    def manifest_paths
      Dir.glob(File.join(@base_dir, "*", "skill.yml")).sort
    end

    def load_path(path)
      data = read_yaml(path)
      validate!(data, path)
      SkillManifest.new(
        id: data.fetch("id"),
        name: data.fetch("name"),
        description: data.fetch("description"),
        entrypoint: data.fetch("entrypoint"),
        actions: data.fetch("actions"),
        enabled_by_default: data.fetch("enabled_by_default"),
        contracts: data.fetch("contracts", {}),
        template_sources: data.fetch("template_sources", []),
        path: path
      )
    rescue StandardError
      nil
    end

    def read_yaml(path)
      content = File.read(path)
      YAML.safe_load(content, permitted_classes: [], aliases: false) || {}
    end

    def validate!(data, path)
      required = %w[id name description entrypoint actions enabled_by_default]
      missing = required.reject { |k| data.key?(k) }
      raise ArgumentError, "invalid skill manifest #{path}: missing #{missing.join(',')}" unless missing.empty?
      raise ArgumentError, "invalid skill manifest #{path}: actions must be array" unless data["actions"].is_a?(Array)
      unless [true, false].include?(data["enabled_by_default"])
        raise ArgumentError, "invalid skill manifest #{path}: enabled_by_default must be boolean"
      end
      validate_contracts!(data, path)
      validate_template_sources!(data, path)
    end

    def validate_contracts!(data, path)
      contracts = data.fetch("contracts", {})
      unless contracts.is_a?(Hash)
        raise ArgumentError, "invalid skill manifest #{path}: contracts must be object"
      end
    end

    def validate_template_sources!(data, path)
      sources = data.fetch("template_sources", [])
      unless sources.is_a?(Array)
        raise ArgumentError, "invalid skill manifest #{path}: template_sources must be array"
      end
      return if sources.empty?

      invalid = sources.any? do |source|
        !source.is_a?(Hash) || source["kind"].to_s.strip.empty? || source["path"].to_s.strip.empty?
      end
      raise ArgumentError, "invalid skill manifest #{path}: template_sources entries must include kind and path" if invalid
    end
  end
end
