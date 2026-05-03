module RuntimeContainers
  class GenerationInputBuilder
    SETUP_ATTRIBUTE_PREFIX = "setup_context.".freeze
    SLOT_KEYS = RuntimeBridge::ProjectContextBuilder::SLOT_KEYS

    def initialize(project:)
      @project = project
    end

    def build
      slots = setup_slots
      {
        "project" => project_data,
        "setup_context" => {
          "slots" => slots
        },
        "stack" => stack_data(slots),
        "workspace" => workspace_data,
        "signals" => input_signals(slots)
      }
    end

    private

    attr_reader :project

    def project_data
      {
        "id" => project.id,
        "name" => project.name,
        "description" => project.description,
        "root_path" => project.root_path,
        "repo_url" => project.repo_url,
        "stack_slug" => project.stack_slug
      }
    end

    def setup_slots
      RuntimeBridge::ProjectContextBuilder.new(project: project).build.fetch("slots")
    end

    def stack_data(slots)
      {
        "project_type" => slot_value(slots, "project_type"),
        "language_runtime" => slot_value(slots, "language_runtime"),
        "framework" => slot_value(slots, "framework"),
        "libraries" => slot_value(slots, "libraries"),
        "stack_slug" => project.stack_slug,
        "runtime_container_profile" => slot_value(slots, "runtime_container_profile"),
        "agent_workflow_mode" => slot_value(slots, "agent_workflow_mode")
      }
    end

    def workspace_data
      workspace = latest_setup_session&.metadata&.fetch("workspace", nil)
      workspace = {} unless workspace.is_a?(Hash)

      {
        "root_path" => project.root_path,
        "repo_url" => project.repo_url,
        "local_repository" => project.repo_url.to_s.start_with?("local://"),
        "materialized" => workspace.fetch("materialized", false),
        "relative_path" => workspace["relative_path"].to_s,
        "runtime_root_path" => workspace["runtime_root_path"].presence || project.root_path,
        "manifest_relative_path" => workspace["manifest_relative_path"].to_s,
        "scaffold_profile" => workspace["scaffold_profile"].to_s,
        "scaffold_files" => Array(workspace["scaffold_files"]).map(&:to_s)
      }
    end

    def latest_setup_session
      @latest_setup_session ||= project.project_setup_sessions.order(created_at: :desc, id: :desc).first
    end

    def input_signals(slots)
      slot_signals = SLOT_KEYS.map do |slot_key|
        slot = slots.fetch(slot_key)
        {
          "key" => "setup_context.#{slot_key}",
          "value" => slot.fetch("value").to_s,
          "source" => slot.fetch("source").to_s,
          "weight" => slot.fetch("weight").to_i
        }
      end
      slot_signals + workspace_signals
    end

    def workspace_signals
      workspace = workspace_data
      [
        {"key" => "project.stack_slug", "value" => project.stack_slug, "source" => "project", "weight" => 5},
        {"key" => "workspace.local_repository", "value" => workspace.fetch("local_repository").to_s, "source" => "workspace", "weight" => 3},
        {"key" => "workspace.scaffold_profile", "value" => workspace.fetch("scaffold_profile"), "source" => "workspace", "weight" => 3}
      ]
    end

    def slot_value(slots, key)
      slots.fetch(key).fetch("value").to_s
    end
  end
end
