module RuntimeContainers
  class ReadinessPolicy
    REQUIRED_FIELDS = %w[
      base_image
      runtime_name
      runtime_version
      working_directory
      validation_command
    ].freeze

    def initialize(runtime_container:)
      @runtime_container = runtime_container
    end

    def ready?
      problems.empty?
    end

    def problems
      @problems ||= required_field_problems +
        command_problems +
        repository_mount_problems +
        generated_file_problems +
        validation_problems +
        risk_problems
    end

    private

    attr_reader :runtime_container

    def required_field_problems
      REQUIRED_FIELDS.filter_map do |field|
        next unless runtime_container.public_send(field).blank?

        problem("missing_required_field", "#{field} is required", "field" => field)
      end
    end

    def command_problems
      return [] if runtime_container.test_commands.any?

      [problem("missing_test_command", "at least one test command is required", "field" => "test_commands")]
    end

    def repository_mount_problems
      mount = runtime_container.repository_mount
      problems = []
      problems << problem("missing_repository_mount_strategy", "repository mount strategy is required", "field" => "repository_mount.strategy") if mount["strategy"].blank?
      problems << problem("missing_repository_mount_target", "repository mount target is required", "field" => "repository_mount.target") if mount["target"].blank?
      problems
    end

    def generated_file_problems
      return [] if generated_files_resolved?

      [
        problem(
          "generated_files_unresolved",
          "generated file proposals must be accepted or explicitly skipped",
          "field" => "generated_files"
        )
      ]
    end

    def generated_files_resolved?
      decision = runtime_container.provenance["generated_files_decision"].to_s
      return true if %w[accepted skipped].include?(decision)

      files = runtime_container.generated_files
      return false if files.empty?

      files.all? do |file|
        file.is_a?(Hash) && %w[accepted skipped].include?(file["status"].to_s)
      end
    end

    def validation_problems
      return [] if runtime_container.validation_status == "passed"
      return [] if runtime_container.validation_status == "skipped" && runtime_container.validation_output_summary.present?

      [
        problem(
          "validation_not_ready",
          "validation must pass or be explicitly skipped with a reason",
          "field" => "validation_status",
          "validation_status" => runtime_container.validation_status
        )
      ]
    end

    def risk_problems
      runtime_container.risks.filter_map do |risk|
        next unless blocking_risk?(risk)

        problem("blocking_risk", risk.fetch("message", "blocking risk remains unresolved"), "field" => "risks")
      end
    end

    def blocking_risk?(risk)
      return false unless risk.is_a?(Hash)

      risk["blocking"] == true || %w[blocking critical].include?(risk["severity"].to_s)
    end

    def problem(code, message, details)
      {
        "code" => code,
        "message" => message,
        "details" => details
      }
    end
  end
end
