module ProjectInitialization
  class Result
    STATUSES = %i[
      invalid_command
      setup_context_required
      repository_resolution_required
      repository_resolved
      repository_resolution_ambiguous
      initialization_cancelled
      initialization_completed
      initialization_failed
      initialization_incomplete
    ].freeze

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

    def self.setup_context_required(command, missing_slots:, next_prompt_intent:)
      new(
        status: :setup_context_required,
        next_action: :collect_setup_context,
        project: {
          name: command.project_name,
          directory_name: command.directory_name,
          description: command.description,
          missing_slots: missing_slots
        },
        repository: {
          input: command.repository_input,
          required: false
        },
        guided_alignment: {
          requested: command.guided_alignment,
          next_prompt_intent: next_prompt_intent
        },
        errors: {}
      )
    end

    def self.repository_resolved(command, repository)
      new(
        status: :repository_resolved,
        next_action: :confirm_repository,
        project: {
          name: command.project_name,
          directory_name: command.directory_name,
          description: command.description
        },
        repository: {
          input: command.repository_input,
          canonical: repository[:canonical],
          source: repository[:source]
        },
        guided_alignment: {
          requested: command.guided_alignment
        },
        errors: {}
      )
    end

    def self.repository_resolution_ambiguous(command, clarification)
      new(
        status: :repository_resolution_ambiguous,
        next_action: :clarify_repository,
        project: {
          name: command.project_name,
          directory_name: command.directory_name,
          description: command.description
        },
        repository: {
          input: command.repository_input,
          clarification: clarification
        },
        guided_alignment: {
          requested: command.guided_alignment
        },
        errors: {}
      )
    end

    def self.initialization_cancelled(command)
      new(
        status: :initialization_cancelled,
        next_action: :abort_initialization,
        project: {
          name: command.project_name,
          directory_name: command.directory_name,
          description: command.description,
          created: false
        },
        repository: {
          input: command.repository_input,
          created: false
        },
        guided_alignment: {
          requested: command.guided_alignment,
          executed: false
        },
        errors: {}
      )
    end

    def self.initialization_completed(command, resolved_repository, context)
      new(
        status: :initialization_completed,
        next_action: :initialization_done,
        project: {
          name: command.project_name,
          directory_name: command.directory_name,
          description: command.description,
          id: context[:project][:id],
          created: true
        },
        repository: {
          input: command.repository_input,
          canonical: resolved_repository[:canonical],
          source: resolved_repository[:source],
          id: context[:repository][:id],
          created: true
        },
        guided_alignment: {
          requested: command.guided_alignment,
          executed: false
        },
        errors: {}
      )
    end

    def self.initialization_failed(command, resolved_repository, context, message, reconciliation)
      new(
        status: :initialization_failed,
        next_action: :report_failure,
        project: {
          name: command.project_name,
          directory_name: command.directory_name,
          description: command.description,
          id: context[:project]&.[](:id),
          created: !context[:project].nil?
        },
        repository: {
          input: command.repository_input,
          canonical: resolved_repository[:canonical],
          source: resolved_repository[:source],
          id: context[:repository]&.[](:id),
          created: !context[:repository].nil?
        },
        guided_alignment: {
          requested: command.guided_alignment,
          executed: false
        },
        errors: {
          initialization: {
            message: message,
            reconciliation: reconciliation
          }
        }
      )
    end

    def self.initialization_incomplete(command, resolved_repository, context, message, reconciliation)
      new(
        status: :initialization_incomplete,
        next_action: :manual_reconciliation_required,
        project: {
          name: command.project_name,
          directory_name: command.directory_name,
          description: command.description,
          id: context[:project]&.[](:id),
          created: !context[:project].nil?
        },
        repository: {
          input: command.repository_input,
          canonical: resolved_repository[:canonical],
          source: resolved_repository[:source],
          id: context[:repository]&.[](:id),
          created: !context[:repository].nil?
        },
        guided_alignment: {
          requested: command.guided_alignment,
          executed: false
        },
        errors: {
          initialization: {
            message: message,
            reconciliation: reconciliation
          }
        }
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
