module RuntimeContainers
  class ValidationService
    VALIDATION_STATUSES = %w[passed failed skipped stale].freeze

    Result = Struct.new(:runtime_container, :changed_fields, keyword_init: true)

    def initialize(project:, status:, output_summary:, validation_command: nil)
      @project = project
      @status = status.to_s
      @output_summary = output_summary.to_s
      @validation_command = validation_command
    end

    def call
      raise ArgumentError, "validation_status is invalid" unless VALIDATION_STATUSES.include?(status)
      raise ArgumentError, "validation skipped requires a reason" if status == "skipped" && output_summary.blank?

      runtime_container = project.runtime_container
      raise ActiveRecord::RecordNotFound, "Runtime Containers configuration was not found" unless runtime_container

      before_state = runtime_container.to_state
      runtime_container.validation_status = status
      runtime_container.validation_output_summary = output_summary
      runtime_container.validation_command = validation_command.to_s if validation_command.present?
      runtime_container.readiness = readiness_after_validation(runtime_container)
      runtime_container.save!

      Result.new(
        runtime_container: runtime_container.reload,
        changed_fields: Comparison::FIELDS.select { |field| before_state[field] != runtime_container.to_state[field] }
      )
    end

    private

    attr_reader :project, :status, :output_summary, :validation_command

    def readiness_after_validation(runtime_container)
      case status
      when "passed", "skipped"
        runtime_container.readiness == "ready" ? "ready" : "validated"
      when "failed"
        "blocked"
      else
        runtime_container.readiness == "blocked" ? "blocked" : "edited"
      end
    end
  end
end
