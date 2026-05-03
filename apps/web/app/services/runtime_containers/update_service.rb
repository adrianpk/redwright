module RuntimeContainers
  class UpdateService
    ASSIGNABLE_FIELDS = %w[
      profile
      status
      readiness
      base_image
      runtime_name
      runtime_version
      working_directory
      system_packages
      dependency_commands
      test_commands
      lint_commands
      build_commands
      format_commands
      repository_mount
      cache_mounts
      environment
      secret_placeholders
      network_policy
      user_policy
      validation_command
      validation_output_summary
      generated_files
      provenance
      assumptions
      missing_information
      risks
    ].freeze

    Result = Struct.new(:runtime_container, :changed_fields, keyword_init: true)

    def initialize(project:, attributes:)
      @project = project
      @attributes = attributes.is_a?(Hash) ? attributes : {}
    end

    def call
      runtime_container = project.runtime_container || project.build_runtime_container
      before_state = runtime_container.to_state
      runtime_container.assign_attributes(assignable_attributes)
      normalize_readiness_after_edit(runtime_container)
      runtime_container.save!

      Result.new(
        runtime_container: runtime_container.reload,
        changed_fields: changed_fields(before_state, runtime_container.to_state)
      )
    end

    private

    attr_reader :project, :attributes

    def assignable_attributes
      source = attributes.transform_keys(&:to_s)
      ASSIGNABLE_FIELDS.each_with_object({}) do |field, attrs|
        attrs[field.to_sym] = source[field] if source.key?(field)
      end
    end

    def normalize_readiness_after_edit(runtime_container)
      return if assignable_attributes.key?(:readiness)
      return if runtime_container.readiness == "blocked"

      runtime_container.readiness = "edited"
    end

    def changed_fields(before_state, after_state)
      Comparison::FIELDS.select { |field| before_state[field] != after_state[field] }
    end
  end
end
