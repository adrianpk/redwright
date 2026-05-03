module ProjectSetup
  class CommandQueryHandlers
    ERROR_SETUP_STATUSES = %i[
      invalid_command
      initialization_failed
      initialization_incomplete
    ].freeze

    def self.register(dispatcher)
      new.register(dispatcher)
    end

    def register(dispatcher)
      dispatcher.register_command("StartProjectSetup", method(:start_project_setup))
      dispatcher.register_command("AdvanceProjectSetup", method(:advance_project_setup))
      dispatcher.register_command("CancelProjectSetup", method(:cancel_project_setup))
      dispatcher.register_query("GetProjectSetupSession", method(:get_project_setup_session))
      dispatcher.register_query("ListProjects", method(:list_projects))
      dispatcher.register_query("GetProject", method(:get_project))
      dispatcher
    end

    def start_project_setup(payload:, context:, request_id:)
      command = ProjectInitialization::Command.new(
        project_name: value_from(payload, "project_name", "name"),
        directory_name: value_from(payload, "directory_name"),
        repository_input: value_from(payload, "repository_input"),
        description: value_from(payload, "description"),
        guided_alignment: boolean_from(value_from(payload, "guided_alignment"))
      )
      result = ProjectInitialization::SetupSessionRunner.new(
        command: command,
        actor_identifier: actor_identifier_from(context),
        request_id: request_id,
        source_channel: source_channel_from(context)
      ).call

      setup_result(result, request_id: request_id)
    end

    def advance_project_setup(payload:, context:, request_id:)
      session = find_session(value_from(payload, "session_id"))
      return missing_session_result(request_id: request_id) unless session

      answer = value_from(payload, "answer").to_s.strip
      return invalid_payload_result(request_id: request_id, message: "answer is required") if answer.empty?

      context_replay = ContextLoopService.new(session: session).replay(request_id: request_id)
      return context_loop_result(context_replay, request_id: request_id) if context_replay

      alignment_replay = GuidedAlignmentService.new(session: session).replay(request_id: request_id)
      return guided_alignment_result(alignment_replay, request_id: request_id) if alignment_replay

      if session.current_state == "collecting_context"
        context_result = ContextLoopService.new(session: session).advance!(
          answer: answer,
          normalized_fields: hash_from(value_from(payload, "normalized_fields")),
          source_channel: source_channel_from(context),
          request_id: request_id
        )
        return context_loop_result(context_result, request_id: request_id)
      end

      normalized_fields = hash_from(value_from(payload, "normalized_fields"))
      if session.current_state == "collecting_alignment"
        alignment_result = GuidedAlignmentService.new(session: session).advance!(
          answer: answer,
          normalized_fields: normalized_fields,
          source_channel: source_channel_from(context),
          request_id: request_id
        )
        return guided_alignment_result(alignment_result, request_id: request_id)
      end

      if session.terminal?
        return completed_context_session_result(session, request_id: request_id) if completion_control?(answer) && completed_context_session?(session)

        return terminal_session_result(session, request_id: request_id)
      end

      turn = StateMachine.new(session: session).record_turn!(
        question: session.pending_question.presence || "Advance project setup",
        answer: answer,
        normalized_fields: normalized_fields,
        source_channel: source_channel_from(context),
        request_id: request_id
      )

      CommandQuery::Result.ok(
        request_id: request_id,
        data: session_data(session.reload, summary: "Project setup advanced."),
        effects: [
          {
            "type" => "project_setup_turn_recorded",
            "session_id" => session.id,
            "turn_index" => turn.turn_index
          }
        ]
      )
    end

    def cancel_project_setup(payload:, context:, request_id:)
      session = find_session(value_from(payload, "session_id"))
      return missing_session_result(request_id: request_id) unless session

      if session.terminal?
        return CommandQuery::Result.ok(
          request_id: request_id,
          data: session_data(session, summary: "Project setup is already terminal."),
          effects: []
        )
      end

      StateMachine.new(session: session).transition_to!("cancelled", terminal_reason: "cancelled_by_user")
      CommandQuery::Result.ok(
        request_id: request_id,
        data: session_data(session.reload, summary: "Project setup cancelled."),
        effects: [
          {
            "type" => "project_setup_cancelled",
            "session_id" => session.id,
            "actor_identifier" => actor_identifier_from(context)
          }
        ]
      )
    rescue StateMachine::InvalidTransition => e
      CommandQuery::Result.new(
        status: "error",
        request_id: request_id,
        data: session_data(session.reload, summary: "Project setup could not be cancelled."),
        effects: [],
        errors: [
          {
            code: "invalid_setup_transition",
            message: e.message,
            details: []
          }
        ]
      )
    end

    def get_project_setup_session(payload:, context:, request_id:)
      session = find_session(value_from(payload, "session_id"))
      return missing_session_result(request_id: request_id) unless session

      CommandQuery::Result.ok(
        request_id: request_id,
        data: session_data(session, summary: "Project setup session retrieved."),
        effects: []
      )
    end

    def list_projects(payload:, context:, request_id:)
      projects = Project.order(:name).map do |project|
        project_data(project)
      end

      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "summary" => "Projects retrieved.",
          "projects" => projects,
          "count" => projects.length
        },
        effects: []
      )
    end

    def get_project(payload:, context:, request_id:)
      project = Project.find_by(id: value_from(payload, "project_id"))
      return missing_project_result(request_id: request_id) unless project

      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "summary" => "Project retrieved.",
          "project" => project_data(project),
          "project_id" => project.id
        },
        effects: []
      )
    end

    private

    def setup_result(result, request_id:)
      data = setup_result_data(result)
      errors = setup_errors_from(result)

      CommandQuery::Result.new(
        status: ERROR_SETUP_STATUSES.include?(result.status) ? "error" : "ok",
        request_id: request_id,
        data: data,
        effects: setup_effects_from(result),
        errors: errors
      )
    end

    def setup_result_data(result)
      session = result.setup_session
      {
        "status" => session&.status || result.status.to_s,
        "session_id" => session&.id,
        "project_id" => session&.project_id || result.project[:id],
        "state" => session&.current_state,
        "next_prompt" => session&.pending_question,
        "next_prompt_intent" => next_prompt_intent_from(session, result),
        "summary" => setup_summary_from(result),
        "repository" => string_keyed(result.repository),
        "project" => string_keyed(result.project),
        "setup_context" => session&.setup_context || {}
      }
    end

    def setup_effects_from(result)
      session = result.setup_session
      effects = []
      effects << {"type" => "project_setup_session_written", "session_id" => session.id} if session
      effects << {"type" => "project_created", "project_id" => result.project[:id]} if result.project[:created] == true
      effects
    end

    def setup_errors_from(result)
      case result.status
      when :invalid_command
        result.errors.map do |field, message|
          {
            code: "invalid_#{field}",
            message: "#{field} #{message}",
            details: {"field" => field.to_s}
          }
        end
      when :initialization_failed, :initialization_incomplete
        [
          {
            code: result.status.to_s,
            message: result.errors.dig(:initialization, :message).to_s,
            details: string_keyed(result.errors.dig(:initialization, :reconciliation) || {})
          }
        ]
      else
        []
      end
    end

    def setup_summary_from(result)
      case result.status
      when :invalid_command
        "Project setup command is invalid."
      when :setup_context_required
        "Project setup started."
      when :repository_resolution_ambiguous
        "Repository input requires clarification."
      when :initialization_cancelled
        "Project setup cancelled."
      when :initialization_completed
        if result.setup_session&.current_state == "collecting_alignment"
          "Project created; guided alignment is ready to continue."
        else
          "Project created; setup completed."
        end
      when :initialization_failed
        "Project setup failed and was reconciled."
      when :initialization_incomplete
        "Project setup failed and needs reconciliation."
      else
        result.status.to_s
      end
    end

    def session_data(session, summary:)
      {
        "status" => session.status,
        "session_id" => session.id,
        "project_id" => session.project_id,
        "state" => session.current_state,
        "next_prompt" => session.pending_question,
        "next_prompt_intent" => session.metadata["next_prompt_intent"] || {},
        "summary" => summary,
        "repository_input" => session.repository_input,
        "resolved_repository" => session.resolved_repository,
        "setup_context" => session.setup_context,
        "turn_counter" => session.turn_counter,
        "terminal_reason" => session.terminal_reason
      }
    end

    def guided_alignment_result(result, request_id:)
      data = session_data(result.session.reload, summary: result.summary).merge(result.data)
      return CommandQuery::Result.ok(request_id: request_id, data: data, effects: result.effects) if result.ok?

      CommandQuery::Result.new(
        status: "error",
        request_id: request_id,
        data: data,
        effects: result.effects,
        errors: result.errors
      )
    end

    def context_loop_result(result, request_id:)
      data = session_data(result.session.reload, summary: result.summary).merge(result.data)
      return CommandQuery::Result.ok(request_id: request_id, data: data, effects: result.effects) if result.ok?

      CommandQuery::Result.new(
        status: "error",
        request_id: request_id,
        data: data,
        effects: result.effects,
        errors: result.errors
      )
    end

    def next_prompt_intent_from(session, result)
      return {} unless session

      stored = session.metadata["next_prompt_intent"]
      return stored if stored.is_a?(Hash)

      intent = result.guided_alignment[:next_prompt_intent]
      intent.is_a?(Hash) ? intent.transform_keys(&:to_s) : {}
    end

    def project_data(project)
      {
        "id" => project.id,
        "name" => project.name,
        "description" => project.description,
        "root_path" => project.root_path,
        "repo_url" => project.repo_url,
        "stack_slug" => project.stack_slug
      }
    end

    def completed_context_session_result(session, request_id:)
      CommandQuery::Result.ok(
        request_id: request_id,
        data: completed_context_session_data(session),
        effects: [
          {
            "type" => "project_setup_completion_reused",
            "session_id" => session.id,
            "project_id" => session.project_id
          }
        ]
      )
    end

    def completed_context_session_data(session)
      metadata = session.metadata
      session_data(session, summary: "Project created; setup completed.").merge(
        "project" => metadata["materialized_project"] || project_data(session.project),
        "board_id" => metadata["board_id"],
        "setup_summary_document_id" => metadata["setup_summary_document_id"],
        "starter_ticket_id" => metadata["starter_ticket_id"],
        "setup_project_attribute_ids" => metadata["setup_project_attribute_ids"] || []
      )
    end

    def completed_context_session?(session)
      session.current_state == "completed" &&
        session.project_id.present? &&
        session.metadata["setup_completion_materialized"] == true
    end

    def completion_control?(answer)
      %w[/done done].include?(answer.to_s.strip.downcase)
    end

    def terminal_session_result(session, request_id:)
      CommandQuery::Result.new(
        status: "error",
        request_id: request_id,
        data: session_data(session, summary: "Project setup session is terminal."),
        effects: [],
        errors: [
          {
            code: "terminal_setup_session",
            message: "project setup session is terminal",
            details: []
          }
        ]
      )
    end

    def missing_session_result(request_id:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "project_setup_session_not_found",
        message: "project setup session was not found"
      )
    end

    def missing_project_result(request_id:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "project_not_found",
        message: "project was not found"
      )
    end

    def invalid_payload_result(request_id:, message:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "invalid_payload",
        message: message
      )
    end

    def find_session(session_id)
      return nil if session_id.blank?

      ProjectSetupSession.find_by(id: session_id)
    end

    def value_from(hash, *keys)
      source = hash_from(hash)
      keys.each do |key|
        return source[key.to_s] if source.key?(key.to_s)
        return source[key.to_sym] if source.key?(key.to_sym)
      end
      nil
    end

    def hash_from(value)
      value.is_a?(Hash) ? value : {}
    end

    def string_keyed(value)
      return {} unless value.is_a?(Hash)

      value.to_h.transform_keys(&:to_s)
    end

    def boolean_from(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end

    def actor_identifier_from(context)
      value_from(context, "actor_identifier", "actor_id").to_s
    end

    def source_channel_from(context)
      value_from(context, "source_channel").presence || "api"
    end
  end
end
