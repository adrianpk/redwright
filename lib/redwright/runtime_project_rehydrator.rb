# frozen_string_literal: true

require_relative "project_store"
require_relative "project_manifest"

module Redwright
  class RuntimeProjectRehydrator
    RehydrationResult = Struct.new(:rehydrated_count, :fallback_count, :errors, keyword_init: true)

    def initialize(db_path:, projects_root:, project_manifest: ProjectManifest.new)
      @db_path = db_path
      @projects_root = projects_root
      @project_manifest = project_manifest
      @project_store = ProjectStore.new(db_path)
    end

    def run!
      return RehydrationResult.new(rehydrated_count: 0, fallback_count: 0, errors: []) unless Dir.exist?(@projects_root)
      # Preserve sqlite-backed runtime state when already hydrated.
      return RehydrationResult.new(rehydrated_count: 0, fallback_count: 0, errors: []) unless @project_store.list.empty?

      rehydrated = 0
      fallback = 0
      errors = []

      project_dirs.each do |project_path|
        manifest_path = File.join(project_path, ".redwright", "manifest.yml")
        manifest_result = @project_manifest.load(manifest_path)
        if manifest_result.valid?
          register_from_manifest(project_path: project_path, data: manifest_result.data)
          rehydrated += 1
        else
          register_fallback(project_path: project_path)
          fallback += 1
          errors << {
            path: project_path,
            reason: manifest_result.errors.join(",")
          }
        end
      rescue StandardError => e
        register_fallback(project_path: project_path)
        fallback += 1
        errors << { path: project_path, reason: e.message }
      end

      RehydrationResult.new(rehydrated_count: rehydrated, fallback_count: fallback, errors: errors)
    end

    private

    def project_dirs
      Dir.children(@projects_root)
         .sort
         .reject { |entry| entry.start_with?(".") || entry == ".worktrees" }
         .map { |entry| File.join(@projects_root, entry) }
         .select { |path| File.directory?(path) }
    end

    def register_from_manifest(project_path:, data:)
      project = data.fetch("project", {})
      provenance = data.fetch("provenance", {})

      aliases = [project["name"], project["slug"]].compact.map(&:to_s).map(&:strip).reject(&:empty?).uniq
      source_type = project["created_via"].to_s == "clone" ? "remote_clone" : "local_new"
      source_ref = provenance["remote_url"].to_s

      @project_store.register(
        path: project_path,
        aliases: aliases,
        source_type: source_type,
        source_ref: source_ref
      )
    end

    def register_fallback(project_path:)
      name = File.basename(project_path)
      @project_store.register(path: project_path, aliases: [name], source_type: "local_new", source_ref: "")
    end
  end
end
