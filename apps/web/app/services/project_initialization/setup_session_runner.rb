module ProjectInitialization
  class SetupSessionRunner
    ALIGNMENT_QUESTION = ProjectSetup::GuidedAlignmentService.first_question.freeze
    REPOSITORY_CLARIFICATION = "Repository input is ambiguous. Use URL, git@host:owner/repo, or owner/repo.".freeze

    Result = Struct.new(:initialization_result, :setup_session, keyword_init: true) do
      def status
        initialization_result.status
      end

      def next_action
        initialization_result.next_action
      end

      def project
        initialization_result.project
      end

      def repository
        initialization_result.repository
      end

      def guided_alignment
        payload = initialization_result.guided_alignment.dup
        return payload if setup_session.nil?

        payload.merge(
          setup_session_id: setup_session.id,
          setup_state: setup_session.current_state,
          pending_question: setup_session.pending_question
        )
      end

      def errors
        initialization_result.errors
      end
    end

    def initialize(
      command:,
      actor_identifier:,
      request_id:,
      source_channel: "web",
      repository_resolver: RepositoryResolver,
      lifecycle: ActiveRecordLifecycle.new
    )
      @command = command
      @actor_identifier = actor_identifier
      @request_id = request_id
      @source_channel = source_channel
      @repository_resolver = repository_resolver
      @lifecycle = lifecycle
    end

    def call
      orchestration = Orchestrator.new(command: command, repository_resolver: repository_resolver).call
      return result(orchestration, setup_session: nil) if orchestration.status == :invalid_command

      ProjectSetupSession.transaction do
        session = create_session!
        machine = ProjectSetup::StateMachine.new(session: session)

        case orchestration.status
        when :setup_context_required
          session.metadata = session.metadata.merge(
            "next_prompt_intent" => stringify_hash(orchestration.guided_alignment[:next_prompt_intent])
          )
          session.save!
          ProjectSetup::SagaState.new(session: session).mark_questionnaire!
          result(orchestration, setup_session: session)
        when :initialization_cancelled
          machine.transition_to!("cancelled", terminal_reason: "cancelled_by_user")
          ProjectSetup::SagaState.new(session: session).mark_cancelled!
          result(orchestration, setup_session: session)
        when :repository_resolution_ambiguous
          machine.transition_to!("awaiting_repository", pending_question: REPOSITORY_CLARIFICATION)
          ProjectSetup::SagaState.new(session: session).mark_questionnaire!
          result(orchestration, setup_session: session)
        when :repository_resolved
          execute_resolved_repository!(orchestration: orchestration, session: session, machine: machine)
        else
          raise "unsupported project initialization status: #{orchestration.status}"
        end
      end
    end

    private

    attr_reader :command, :actor_identifier, :request_id, :source_channel, :repository_resolver, :lifecycle

    def create_session!
      session = ProjectSetupSession.create!(
        source_channel: source_channel,
        actor_identifier: actor_identifier,
        request_id: request_id,
        repository_input: command.repository_input,
        metadata: {
          command: command.to_h,
          project_name: command.project_name,
          directory_name: command.directory_name,
          guided_alignment_requested: command.guided_alignment
        }
      )
      assign_initial_setup_slots(session)
      session.save!
      session
    end

    def assign_initial_setup_slots(session)
      assign_slot_if_present(session, key: "project_name", value: command.project_name, source: "payload")
      assign_slot_if_present(session, key: "description", value: command.description, source: "payload")
      assign_slot_if_present(session, key: "repository", value: command.repository_input, source: "payload")
    end

    def assign_slot_if_present(session, key:, value:, source:)
      return if value.to_s.strip.empty?

      session.assign_setup_slot(key: key, value: value, source: source)
    end

    def stringify_hash(value)
      return {} unless value.is_a?(Hash)

      value.to_h.transform_keys(&:to_s)
    end

    def execute_resolved_repository!(orchestration:, session:, machine:)
      resolved_repository = orchestration.repository.slice(:canonical, :source)
      session.update!(resolved_repository: resolved_repository)

      machine.transition_to!("awaiting_repository_confirmation")
      machine.transition_to!("awaiting_alignment_opt_in")
      machine.transition_to!("ready_to_create")
      machine.transition_to!("creating_project")
      ProjectSetup::SagaState.new(session: session).mark_materialization_started!

      execution = Executor.new(
        command: command,
        resolved_repository: resolved_repository,
        lifecycle: lifecycle
      ).call

      finalize_execution!(execution: execution, session: session, machine: machine)
      result(execution, setup_session: session)
    end

    def finalize_execution!(execution:, session:, machine:)
      case execution.status
      when :initialization_completed
        project = Project.find(execution.project[:id])
        session.project = project
        session.metadata = session.metadata.merge(
          "project_id" => project.id,
          "guided_alignment_pending" => command.guided_alignment == true
        )
        session.save!
        ProjectSetup::SagaState.new(session: session).mark_materialized!(project: project)

        if command.guided_alignment == true
          machine.transition_to!("collecting_alignment", pending_question: ALIGNMENT_QUESTION)
          ProjectSetup::SagaState.new(session: session).mark_questionnaire!
        else
          machine.transition_to!("completed", terminal_reason: "completed_without_alignment")
          ProjectSetup::SagaState.new(session: session).mark_completed!(
            project: project,
            board: nil,
            document: nil,
            starter_ticket: nil,
            attribute_ids: [],
            workspace: {}
          )
        end
      when :initialization_failed
        machine.transition_to!("failed", terminal_reason: "failed_reconciled")
        ProjectSetup::SagaState.new(session: session).mark_failed!(
          reason: execution.errors.dig(:initialization, :message),
          reconciliation: execution.errors.dig(:initialization, :reconciliation) || {},
          effects: [
            HeavyInteractionSagas::Effect.new(
              type: "project_setup_failed",
              visibility: "public",
              data: {
                session_id: session.id,
                terminal_reason: "failed_reconciled"
              }
            ),
            HeavyInteractionSagas::Effect.new(
              type: "project_setup_reconciled",
              visibility: "internal",
              data: {
                session_id: session.id,
                reconciliation_status: execution.errors.dig(:initialization, :reconciliation, :status)
              }
            )
          ]
        )
      when :initialization_incomplete
        machine.transition_to!("needs_reconciliation", terminal_reason: "failed_needs_reconciliation")
        ProjectSetup::SagaState.new(session: session).mark_failed!(
          reason: execution.errors.dig(:initialization, :message),
          reconciliation: execution.errors.dig(:initialization, :reconciliation) || {},
          effects: [
            HeavyInteractionSagas::Effect.new(
              type: "project_setup_failed",
              visibility: "public",
              data: {
                session_id: session.id,
                terminal_reason: "failed_needs_reconciliation"
              }
            ),
            HeavyInteractionSagas::Effect.new(
              type: "project_setup_reconciliation_required",
              visibility: "public",
              data: {
                session_id: session.id,
                reconciliation_status: execution.errors.dig(:initialization, :reconciliation, :status)
              }
            )
          ]
        )
      else
        raise "unsupported project execution status: #{execution.status}"
      end
    end

    def result(initialization_result, setup_session:)
      Result.new(initialization_result: initialization_result, setup_session: setup_session)
    end
  end
end
