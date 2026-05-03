module RuntimeBridge
  class ProjectContextBuilder
    DEFAULT_RUNTIME_CONTAINER_PROFILE = "ephemeral_docker".freeze
    DEFAULT_AGENT_WORKFLOW_MODE = "manual".freeze
    SETUP_ATTRIBUTE_PREFIX = "setup_context.".freeze
    SLOT_KEYS = %w[
      project_name
      description
      project_type
      language_runtime
      repository
      stack
      framework
      libraries
      patterns
      conventions
      runtime_container_profile
      agent_workflow_mode
    ].freeze

    def initialize(project:)
      @project = project
    end

    def build
      slots = setup_slots
      {
        "project" => project_data,
        "slots" => slots,
        "runtime" => runtime_data(slots)
      }
    end

    private

    attr_reader :project

    def project_data
      {
        "id" => project.id,
        "name" => project.name,
        "root_path" => project.root_path,
        "repo_url" => project.repo_url,
        "stack_slug" => project.stack_slug
      }
    end

    def setup_slots
      attributes = project.project_attributes.where(key: SLOT_KEYS.map { |key| "#{SETUP_ATTRIBUTE_PREFIX}#{key}" }).index_by(&:key)
      SLOT_KEYS.each_with_object({}) do |slot_key, slots|
        attribute = attributes["#{SETUP_ATTRIBUTE_PREFIX}#{slot_key}"]
        slots[slot_key] = slot_data(slot_key: slot_key, attribute: attribute)
      end
    end

    def slot_data(slot_key:, attribute:)
      value = attribute&.value.to_s.strip
      value = default_slot_value(slot_key) if value.empty?
      {
        "value" => value,
        "source" => attribute&.source || "runtime_default",
        "weight" => attribute&.weight || default_slot_weight(slot_key)
      }
    end

    def runtime_data(slots)
      {
        "container_profile" => slots.fetch("runtime_container_profile").fetch("value"),
        "agent_workflow_mode" => slots.fetch("agent_workflow_mode").fetch("value"),
        "stack_slug" => project.stack_slug,
        "language_runtime" => slots.fetch("language_runtime").fetch("value"),
        "framework" => slots.fetch("framework").fetch("value"),
        "libraries" => slots.fetch("libraries").fetch("value")
      }
    end

    def default_slot_value(slot_key)
      case slot_key
      when "project_name"
        project.name
      when "description"
        project.description
      when "repository"
        project.repo_url
      when "stack"
        project.stack_slug
      when "runtime_container_profile"
        DEFAULT_RUNTIME_CONTAINER_PROFILE
      when "agent_workflow_mode"
        DEFAULT_AGENT_WORKFLOW_MODE
      else
        ""
      end
    end

    def default_slot_weight(slot_key)
      ProjectSetupSession::SETUP_SLOT_WEIGHTS.fetch(slot_key, 1).clamp(1, 5)
    end
  end
end
