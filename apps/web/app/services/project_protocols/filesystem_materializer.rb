require "fileutils"
require "yaml"

module ProjectProtocols
  class FilesystemMaterializer
    DEFAULT_RELATIVE_ROOT = File.join("_workspace", "Projects").freeze

    def initialize(project:, workspace_path: nil, manifest_path: nil, projects_root: nil)
      @project = project
      @workspace_path = workspace_path.presence
      @manifest_path = manifest_path.presence
      @projects_root = projects_root.presence || ENV["REDWRIGHT_LOCAL_PROJECTS_ROOT"].presence || default_projects_root
    end

    def call(update_manifest: false)
      return skipped_result("non_local_repository") unless local_repository?
      return skipped_result("missing_protocol") unless project.protocol

      path = resolved_workspace_path
      return skipped_result("workspace_missing", workspace_path: path) unless Dir.exist?(path)

      files = materialized_files(path)
      remove_stale_files(path, files.map { |file| file.fetch("path") })
      update_manifest_file(path, files) if update_manifest

      {
        "status" => "materialized",
        "workspace_path" => path,
        "root_entrypoint" => "AGENTS.md",
        "files" => files
      }
    end

    private

    attr_reader :project, :projects_root

    def default_projects_root
      return Rails.root.join("tmp", "redwright-local-projects").expand_path.to_s if Rails.env.test?

      Rails.root.join("..", "..", DEFAULT_RELATIVE_ROOT).expand_path.to_s
    end

    def local_repository?
      project.repo_url.to_s.start_with?("local://")
    end

    def resolved_workspace_path
      @workspace_path || File.join(projects_root, workspace_slug)
    end

    def workspace_slug
      slug = File.basename(project.root_path.to_s)
      slug = project.name.to_s if slug.empty? || slug == "."
      slug.downcase.gsub(/[^a-z0-9._-]+/, "-").gsub(/\A-+|-+\z/, "")
    end

    def materialized_files(path)
      current_protocol.documents.map do |document|
        absolute_path = File.join(path, document.path)
        FileUtils.mkdir_p(File.dirname(absolute_path))
        File.write(absolute_path, normalized_body(document.body))

        {
          "path" => document.path,
          "title" => document.title,
          "absolute_path" => absolute_path
        }
      end
    end

    def current_protocol
      project.reload.protocol
    end

    def normalized_body(body)
      "#{body.to_s.rstrip}\n"
    end

    def remove_stale_files(path, desired_paths)
      stale_paths(path, desired_paths).each do |relative_path|
        absolute_path = File.join(path, relative_path)
        File.delete(absolute_path) if File.file?(absolute_path)
      end
    end

    def stale_paths(path, desired_paths)
      previous_files = existing_manifest(path).dig("protocols", "files")
      previous_files = [] unless previous_files.is_a?(Array)

      previous_files
        .filter_map { |entry| entry.is_a?(Hash) ? entry["path"].to_s : nil }
        .reject(&:empty?)
        .uniq
        .reject { |relative_path| desired_paths.include?(relative_path) }
    end

    def update_manifest_file(path, files)
      manifest_path = resolved_manifest_path(path)
      return unless File.file?(manifest_path)

      payload = existing_manifest(path)
      payload["protocols"] = {
        "status" => "materialized",
        "root_entrypoint" => "AGENTS.md",
        "files" => files,
        "state" => project.reload.protocol_state
      }
      File.write(manifest_path, YAML.dump(payload))
    end

    def existing_manifest(path)
      manifest_path = resolved_manifest_path(path)
      return {} unless File.file?(manifest_path)

      payload = YAML.safe_load(File.read(manifest_path))
      payload.is_a?(Hash) ? payload : {}
    end

    def resolved_manifest_path(path)
      @manifest_path || File.join(path, ".redwright", "manifest.yml")
    end

    def skipped_result(reason, workspace_path: resolved_workspace_path)
      {
        "status" => "skipped",
        "reason" => reason,
        "workspace_path" => workspace_path,
        "root_entrypoint" => "AGENTS.md",
        "files" => []
      }
    end
  end
end
