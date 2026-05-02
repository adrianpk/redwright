module ProjectInitialization
  class Result
    STATUSES = %i[invalid_command repository_resolution_required].freeze

    attr_reader :status, :next_action, :project, :repository, :guided_alignment, :errors

    def initialize(status:, next_action:, project:, repository:, guided_alignment:, errors:)
      @status = status
      @next_action = next_action
      @project = project
      @repository = repository
      @guided_alignment = guided_alignment
      @errors = errors
    end

    def self.invalid_command(command_errors)
      new(
        status: :invalid_command,
        next_action: :reject_command,
        project: {},
        repository: {},
        guided_alignment: {},
        errors: command_errors
      )
    end

    def self.repository_resolution_required(command)
      new(
        status: :repository_resolution_required,
        next_action: :resolve_repository,
        project: {
          name: command.project_name,
          directory_name: command.directory_name
        },
        repository: {
          input: command.repository_input
        },
        guided_alignment: {
          requested: command.guided_alignment
        },
        errors: {}
      )
    end

    def to_h
      {
        status: status,
        next_action: next_action,
        project: project,
        repository: repository,
        guided_alignment: guided_alignment,
        errors: errors
      }
    end
  end
end
