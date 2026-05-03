require "fileutils"
require "yaml"

module ProjectSetup
  class LocalWorkspaceMaterializer
    DEFAULT_RELATIVE_ROOT = File.join("_workspace", "Projects").freeze
    MATERIALIZATION_STATUS = "materialized_planned".freeze
    INITIAL_IMPLEMENTATION_STATUS = "planned".freeze
    VALIDATION_STATUS = "skipped".freeze

    def initialize(session:, project:, starter_ticket: nil, projects_root: nil)
      @session = session
      @project = project
      @starter_ticket = starter_ticket
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
      readme_path = File.join(path, "README.md")
      setup_notes_path = File.join(manifest_dir, "setup-notes.md")
      File.write(readme_path, readme_body)
      File.write(setup_notes_path, setup_notes_body)

      {
        "status" => "materialized",
        "materialization_status" => MATERIALIZATION_STATUS,
        "initial_implementation_status" => INITIAL_IMPLEMENTATION_STATUS,
        "validation_status" => VALIDATION_STATUS,
        "runnable" => false,
        "reason" => materialization_reason,
        "materialized" => true,
        "path" => path,
        "relative_path" => File.join(DEFAULT_RELATIVE_ROOT, slug),
        "manifest_path" => manifest_path,
        "manifest_relative_path" => File.join(DEFAULT_RELATIVE_ROOT, slug, ".redwright", "manifest.yml"),
        "readme_path" => readme_path,
        "readme_relative_path" => File.join(DEFAULT_RELATIVE_ROOT, slug, "README.md"),
        "setup_notes_path" => setup_notes_path,
        "setup_notes_relative_path" => File.join(DEFAULT_RELATIVE_ROOT, slug, ".redwright", "setup-notes.md"),
        "runtime_root_path" => @project.root_path,
        "repo_url" => @project.repo_url,
        "linked_ticket_ids" => linked_ticket_ids
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
        "materialization_status" => "skipped",
        "initial_implementation_status" => INITIAL_IMPLEMENTATION_STATUS,
        "validation_status" => VALIDATION_STATUS,
        "runnable" => false,
        "materialized" => false,
        "reason" => "non_local_repository",
        "runtime_root_path" => @project.root_path,
        "repo_url" => @project.repo_url,
        "linked_ticket_ids" => linked_ticket_ids
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
        "materialization" => {
          "status" => MATERIALIZATION_STATUS,
          "runnable" => false,
          "reason" => materialization_reason,
          "workspace_relative_path" => File.join(DEFAULT_RELATIVE_ROOT, workspace_slug),
          "setup_notes_relative_path" => File.join(DEFAULT_RELATIVE_ROOT, workspace_slug, ".redwright", "setup-notes.md")
        },
        "initial_implementation" => {
          "status" => INITIAL_IMPLEMENTATION_STATUS,
          "runnable" => false,
          "reason" => initial_implementation_reason,
          "linked_ticket_ids" => linked_ticket_ids
        },
        "validation" => {
          "status" => VALIDATION_STATUS,
          "command" => "",
          "reason" => "validation is skipped until a runnable scaffold exists"
        },
        "runtime" => {
          "container_profile" => slot_value("runtime_container_profile")
        },
        "workflow" => {
          "agent_workflow_mode" => slot_value("agent_workflow_mode"),
          "linked_ticket_ids" => linked_ticket_ids
        }
      }
    end

    def readme_body
      [
        "# #{@project.name}",
        "",
        @project.description.to_s,
        "",
        "## Setup Status",
        "",
        "- Materialization: #{MATERIALIZATION_STATUS}",
        "- Initial implementation: #{INITIAL_IMPLEMENTATION_STATUS}",
        "- Runnable: no",
        "- Validation: #{VALIDATION_STATUS}",
        "- Reason: #{materialization_reason}",
        "",
        "## Next Step",
        "",
        starter_ticket_line
      ].join("\n")
    end

    def setup_notes_body
      lines = [
        "# RedWright Setup Notes",
        "",
        "This workspace was materialized by Rails project setup.",
        "",
        "## Outcome",
        "",
        "- Materialization status: #{MATERIALIZATION_STATUS}",
        "- Initial implementation status: #{INITIAL_IMPLEMENTATION_STATUS}",
        "- Validation status: #{VALIDATION_STATUS}",
        "- Runnable: no",
        "- Reason: #{materialization_reason}",
        "",
        "## Canonical Setup Slots"
      ]
      @session.setup_slots.each_value do |slot|
        lines << "- #{slot.fetch("key")}: #{slot["value"]} (#{slot["status"]})"
      end
      lines.concat(
        [
          "",
          "## Linked Tickets",
          "",
          starter_ticket_line
        ]
      )
      lines.join("\n")
    end

    def starter_ticket_line
      return "- Initial implementation ticket: #{@starter_ticket.id}" if @starter_ticket

      "- Initial implementation ticket: pending"
    end

    def materialization_reason
      if go_cli_context?
        "Go CLI scaffold generation is planned for a later setup slice"
      else
        "no runnable scaffold profile exists for this setup context yet"
      end
    end

    def initial_implementation_reason
      "initial implementation is represented by a Rails board ticket"
    end

    def linked_ticket_ids
      @starter_ticket ? [@starter_ticket.id] : []
    end

    def go_cli_context?
      [slot_value("project_type"), slot_value("language_runtime")].join(" ").downcase.match?(/\bcli\b.*\bgo\b|\bgo\b.*\bcli\b/)
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
