module RuntimeContainers
  class Comparison
    FIELDS = %w[
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
      validation_status
      validation_output_summary
      generated_files
      provenance
      assumptions
      missing_information
      risks
    ].freeze

    def initialize(active_state:, proposed_state:)
      @active_state = active_state
      @proposed_state = proposed_state
    end

    def to_h
      {
        "changed" => changes.any?,
        "changed_fields" => changes.map { |change| change.fetch("field") },
        "changes" => changes
      }
    end

    private

    attr_reader :active_state, :proposed_state

    def changes
      @changes ||= FIELDS.filter_map do |field|
        active = active_state[field]
        proposed = proposed_state[field]
        next if active == proposed

        {
          "field" => field,
          "active" => active,
          "proposed" => proposed
        }
      end
    end
  end
end
