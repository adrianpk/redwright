require "fileutils"
require "yaml"

module ProjectSetup
  class LocalWorkspaceMaterializer
    DEFAULT_RELATIVE_ROOT = File.join("_workspace", "Projects").freeze

    def initialize(session:, project:, projects_root: nil)
      @session = session
      @project = project
      @projects_root = projects_root.presence || ENV["REDWRIGHT_LOCAL_PROJECTS_ROOT"].presence || default_projects_root
    end

    def call
      return skipped_workspace unless local_repository?

      slug = workspace_slug
      path = File.join(@projects_root, slug)
      manifest_dir = File.join(path, ".redwright")
      manifest_path = File.join(manifest_dir, "manifest.yml")
      FileUtils.mkdir_p(manifest_dir)
      File.write(manifest_path, YAML.dump(manifest_payload(manifest_path: manifest_path)))

      {
        "status" => "materialized",
        "materialized" => true,
        "path" => path,
        "relative_path" => File.join(DEFAULT_RELATIVE_ROOT, slug),
        "manifest_path" => manifest_path,
        "manifest_relative_path" => File.join(DEFAULT_RELATIVE_ROOT, slug, ".redwright", "manifest.yml"),
        "runtime_root_path" => @project.root_path,
        "repo_url" => @project.repo_url
      }
    end

    private

    def default_projects_root
      return Rails.root.join("tmp", "redwright-local-projects").expand_path.to_s if Rails.env.test?

      Rails.root.join("..", "..", DEFAULT_RELATIVE_ROOT).expand_path.to_s
    end

    def local_repository?
      @project.repo_url.to_s.start_with?("local://")
    end

    def skipped_workspace
      {
        "status" => "skipped",
        "materialized" => false,
        "reason" => "non_local_repository",
        "runtime_root_path" => @project.root_path,
        "repo_url" => @project.repo_url
      }
    end

    def workspace_slug
      slug = File.basename(@project.root_path.to_s)
      slug = @project.name.to_s if slug.empty? || slug == "."
      slug.downcase.gsub(/[^a-z0-9._-]+/, "-").gsub(/\A-+|-+\z/, "")
    end

    def manifest_payload(manifest_path:)
      existing = existing_manifest(manifest_path)
      created_at = existing.dig("project", "created_at").presence || Time.current.utc.iso8601

      {
        "schema_version" => 1,
        "project" => {
          "id" => @project.id,
          "name" => @project.name,
          "slug" => workspace_slug,
          "stack" => @project.stack_slug,
          "created_via" => "rails_project_setup",
          "created_at" => created_at
        },
        "rails" => {
          "project_id" => @project.id,
          "root_path" => @project.root_path,
          "repo_url" => @project.repo_url
        },
        "setup_context" => @session.setup_context,
        "runtime" => {
          "container_profile" => slot_value("runtime_container_profile")
        },
        "workflow" => {
          "agent_workflow_mode" => slot_value("agent_workflow_mode")
        }
      }
    end

    def existing_manifest(path)
      return {} unless File.file?(path)

      parsed = YAML.safe_load(File.read(path), aliases: false)
      parsed.is_a?(Hash) ? parsed : {}
    rescue Psych::Exception
      {}
    end

    def slot_value(key)
      slot = @session.setup_slot(key)
      return "" unless slot.is_a?(Hash)

      slot["value"].to_s
    end
  end
end
