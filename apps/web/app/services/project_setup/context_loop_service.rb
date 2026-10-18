module ProjectSetup
  class ContextLoopService
    SLOT_ORDER = %w[
      project_name
      description
      project_type
      language_runtime
      framework
      libraries
    ].freeze
    DEFAULT_DESCRIPTION = "Project initialized from conversational setup.".freeze
    DEFAULT_PROJECT_TYPE = "application".freeze
    DEFAULT_LANGUAGE_RUNTIME = "unspecified".freeze
    DEFAULT_FRAMEWORK = "none specified".freeze
    DEFAULT_LIBRARIES = "none specified".freeze
    DEFAULT_STACK = "ruby".freeze
    DEFAULT_RUNTIME_CONTAINER_PROFILE = "ephemeral_docker".freeze
    DEFAULT_AGENT_WORKFLOW_MODE = "manual".freeze
    STARTER_TICKET_TITLE = "Prepare initial implementation plan".freeze
    RUNTIME_CONTAINERS_READINESS_TICKET_TITLE = "Review Runtime Containers readiness".freeze
    STARTER_TICKET_ASSIGNEE = "agent-coder".freeze
    BOARD_COLUMNS = [
      ["backlog", "Backlog"],
      ["in_progress", "In Progress"],
      ["review", "Review"],
      ["approved", "Approved"],
      ["merged", "Merged"]
    ].freeze
    SETUP_ATTRIBUTE_SOURCE = "project_setup".freeze
    SETUP_DOCUMENT_TITLE = "Project Setup Summary".freeze

    Result = Struct.new(:ok, :session, :turn, :summary, :effects, :errors, :data, keyword_init: true) do
      def ok?
        ok == true
      end
    end

    def initialize(session:)
      @session = session
    end

    def replay(request_id:)
      turn = context_turn_for_request(request_id)
      return nil unless turn

      effects = [
        saga_effect("project_setup_turn_reused", visibility: "internal", session_id: session.id, turn_index: turn.turn_index)
      ]
      effects << completion_reused_effect if completion_materialized?

      success(
        turn: turn,
        summary: summary_for(session),
        effects: effects,
        data: completion_materialization_data
      )
    end

    def advance!(answer:, normalized_fields: {}, source_channel:, request_id:)
      cleaned_answer = answer.to_s.strip
      return failure(code: "invalid_setup_context_answer", message: "answer is required") if cleaned_answer.empty?
      return failure(code: "setup_context_not_active", message: "setup context collection is not active") unless session.current_state == "collecting_context"

      result = nil
      ProjectSetupSession.transaction do
        session.lock!

        repeated = context_turn_for_request(request_id)
        if repeated
          effects = [
            saga_effect("project_setup_turn_reused", visibility: "internal", session_id: session.id, turn_index: repeated.turn_index)
          ]
          SagaState.new(session: session).record_effects!(effects)
          result = success(
            turn: repeated,
            summary: summary_for(session),
            effects: effects
          )
          next
        end

        control = control_from(cleaned_answer)
        result = case control
                 when "cancel"
                   cancel_setup!(answer: cleaned_answer, normalized_fields: normalized_fields, source_channel: source_channel, request_id: request_id)
                 when "done"
                   complete_or_request_blocking_slot!(answer: cleaned_answer, normalized_fields: normalized_fields, source_channel: source_channel, request_id: request_id)
                 when "skip"
                   skip_or_request_blocking_slot!(answer: cleaned_answer, normalized_fields: normalized_fields, source_channel: source_channel, request_id: request_id)
                 else
                   record_slot_answer!(answer: cleaned_answer, normalized_fields: normalized_fields, source_channel: source_channel, request_id: request_id)
                 end
      end

      result
    end

    private

    attr_reader :session

    def record_slot_answer!(answer:, normalized_fields:, source_channel:, request_id:)
      slot_key = current_slot_key || next_slot_key
      return complete_setup!(turn: nil) unless slot_key
      normalization = normalize_answer(slot_key: slot_key, answer: answer, normalized_fields: normalized_fields)

      turn = record_context_turn!(
        question: "setup_slot:#{slot_key}",
        answer: answer,
        normalized_fields: turn_fields(
          slot_key: slot_key,
          action: "answer",
          normalized_fields: normalized_fields_from(normalization: normalization, original_fields: normalized_fields),
          value: normalization.value,
          raw_value: normalization.raw_value,
          normalization_status: normalization.status,
          normalization_reason: normalization.normalization_reason
        ),
        source_channel: source_channel,
        request_id: request_id
      )
      if normalization.ambiguous?
        session.assign_setup_slot(
          key: slot_key,
          value: "",
          raw_value: answer,
          source: normalization.source,
          confidence: normalization.confidence,
          status: "ambiguous",
          normalization_reason: normalization.normalization_reason
        )
        session.save!
        store_next_prompt_intent!(slot_key)
        SagaState.new(session: session).mark_questionnaire!
        effects = [
          turn_recorded_effect(turn),
          saga_effect("project_setup_prompt_repeated", visibility: "internal", session_id: session.id, slot: slot_key)
        ]
        SagaState.new(session: session).record_effects!(effects)
        return success(
          turn: turn,
          summary: "Project setup needs a clearer answer.",
          effects: effects
        )
      end

      session.assign_setup_slot(
        key: slot_key,
        value: normalization.value,
        raw_value: normalization.raw_value,
        source: normalization.source,
        confidence: normalization.confidence,
        status: normalization.status,
        normalization_reason: normalization.normalization_reason
      )
      assign_auxiliary_normalized_slots!(current_slot_key: slot_key, normalized_fields: normalization.slot_updates)
      session.save!

      next_slot = next_slot_key
      return complete_setup!(turn: turn) unless next_slot

      store_next_prompt_intent!(next_slot)
      SagaState.new(session: session).mark_questionnaire!
      effects = [
        turn_recorded_effect(turn),
        saga_effect("project_setup_prompt_advanced", visibility: "internal", session_id: session.id, slot: next_slot)
      ]
      SagaState.new(session: session).record_effects!(effects)
      success(
        turn: turn,
        summary: "Project setup context updated.",
        effects: effects
      )
    end

    def skip_or_request_blocking_slot!(answer:, normalized_fields:, source_channel:, request_id:)
      slot_key = current_slot_key || next_slot_key
      return complete_setup!(turn: nil) unless slot_key

      turn = record_context_turn!(
        question: "setup_control:skip",
        answer: answer,
        normalized_fields: turn_fields(slot_key: slot_key, action: "skip", normalized_fields: normalized_fields, value: ""),
        source_channel: source_channel,
        request_id: request_id
      )

      if blocking_slot?(slot_key)
        store_next_prompt_intent!(slot_key)
        SagaState.new(session: session).mark_questionnaire!
        effects = [
          turn_recorded_effect(turn),
          saga_effect("project_setup_prompt_repeated", visibility: "internal", session_id: session.id, slot: slot_key)
        ]
        SagaState.new(session: session).record_effects!(effects)
        return success(
          turn: turn,
          summary: "Project setup still needs a project name.",
          effects: effects
        )
      end

      session.assign_setup_slot(key: slot_key, value: "", source: "user_control", status: "skipped")
      session.save!

      next_slot = next_slot_key
      return complete_setup!(turn: turn) unless next_slot

      store_next_prompt_intent!(next_slot)
      SagaState.new(session: session).mark_questionnaire!
      effects = [
        turn_recorded_effect(turn),
        saga_effect("project_setup_prompt_advanced", visibility: "internal", session_id: session.id, slot: next_slot)
      ]
      SagaState.new(session: session).record_effects!(effects)
      success(
        turn: turn,
        summary: "Project setup slot skipped.",
        effects: effects
      )
    end

    def complete_or_request_blocking_slot!(answer:, normalized_fields:, source_channel:, request_id:)
      missing = missing_blocking_slot
      turn = record_context_turn!(
        question: "setup_control:done",
        answer: answer,
        normalized_fields: turn_fields(slot_key: missing || "completion", action: "done", normalized_fields: normalized_fields, value: ""),
        source_channel: source_channel,
        request_id: request_id
      )

      if missing
        store_next_prompt_intent!(missing)
        SagaState.new(session: session).mark_questionnaire!
        effects = [
          turn_recorded_effect(turn),
          saga_effect("project_setup_prompt_repeated", visibility: "internal", session_id: session.id, slot: missing)
        ]
        SagaState.new(session: session).record_effects!(effects)
        return success(
          turn: turn,
          summary: "Project setup still needs a project name.",
          effects: effects
        )
      end

      complete_setup!(turn: turn)
    end

    def cancel_setup!(answer:, normalized_fields:, source_channel:, request_id:)
      turn = record_context_turn!(
        question: "setup_control:cancel",
        answer: answer,
        normalized_fields: turn_fields(slot_key: "cancellation", action: "cancel", normalized_fields: normalized_fields, value: ""),
        source_channel: source_channel,
        request_id: request_id
      )
      StateMachine.new(session: session).transition_to!("cancelled", terminal_reason: "cancelled_by_user")
      metadata = session.metadata
      metadata.delete("next_prompt_intent")
      session.metadata = metadata
      session.save!
      SagaState.new(session: session).mark_cancelled!
      effects = [
        turn_recorded_effect(turn),
        saga_effect("project_setup_cancelled", visibility: "public", session_id: session.id)
      ]
      SagaState.new(session: session).record_effects!(effects)

      success(
        turn: turn,
        summary: "Project setup cancelled.",
        effects: effects
      )
    end

    def complete_setup!(turn:)
      default_missing_slots!

      StateMachine.new(session: session).transition_to!("ready_to_create")
      StateMachine.new(session: session).transition_to!("creating_project")
      SagaState.new(session: session).mark_materialization_started!

      pipeline_result = materialization_pipeline.call
      project = pipeline_result.outputs.fetch(:project)
      board = pipeline_result.outputs.fetch(:board)
      document = pipeline_result.outputs.fetch(:document)
      starter_ticket = pipeline_result.outputs[:starter_ticket]
      protocol_generation = pipeline_result.outputs[:protocol_generation]
      runtime_generation = pipeline_result.outputs[:runtime_generation]
      runtime_readiness_ticket = pipeline_result.outputs[:runtime_containers_readiness_ticket]
      workspace = pipeline_result.outputs[:workspace]
      attribute_ids = pipeline_result.outputs.fetch(:attribute_ids)
      persist_materialization_steps!(pipeline_result.step_results)
      StateMachine.new(session: session).transition_to!("completed", terminal_reason: "completed_without_alignment")
      SagaState.new(session: session).mark_completed!(
        project: project,
        board: board,
        document: document,
        starter_ticket: starter_ticket,
        attribute_ids: attribute_ids,
        workspace: workspace
      )

      effects = []
      effects << turn_recorded_effect(turn) if turn
      effects.concat(
        [
          saga_effect("project_protocols_initialized", visibility: "internal", session_id: session.id, project_id: project.id),
          saga_effect("project_created", visibility: "public", project_id: project.id),
          saga_effect("setup_context_materialized", visibility: "public", session_id: session.id, project_id: project.id, project_attribute_ids: attribute_ids),
          saga_effect("setup_summary_document_written", visibility: "internal", session_id: session.id, project_id: project.id, document_id: document.id),
          saga_effect("default_board_structure_written", visibility: "internal", session_id: session.id, project_id: project.id, board_id: board.id)
        ]
      )
      if starter_ticket
        effects << saga_effect("setup_starter_ticket_written", visibility: "internal", session_id: session.id, project_id: project.id, board_id: board.id, ticket_id: starter_ticket.id)
      end
      if runtime_generation
        effects << saga_effect(
          "runtime_containers_initialized",
          visibility: "internal",
          session_id: session.id,
          project_id: project.id,
          runtime_container_id: project.runtime_container&.id,
          readiness: project.runtime_container&.readiness,
          generator_source: runtime_generation.generator_source
        )
      end
      if runtime_readiness_ticket
        effects << saga_effect("runtime_containers_readiness_ticket_written", visibility: "internal", session_id: session.id, project_id: project.id, board_id: board.id, ticket_id: runtime_readiness_ticket.id)
      end
      if workspace && workspace["materialized"] == true
        effects << saga_effect("local_workspace_materialized", visibility: "debug", session_id: session.id, project_id: project.id, path: workspace["path"], manifest_path: workspace["manifest_path"])
      end
      effects.concat(
        [
          saga_effect("project_setup_completed", visibility: "public", session_id: session.id, terminal_reason: "completed_without_alignment")
        ]
      )
      SagaState.new(session: session).record_effects!(effects)

      success(
        turn: turn,
        summary: "Project created; setup completed.",
        effects: effects,
        data: materialization_data(
          project: project,
          board: board,
          document: document,
          starter_ticket: starter_ticket,
          protocol_generation: protocol_generation,
          runtime_containers_readiness_ticket: runtime_readiness_ticket,
          attribute_ids: attribute_ids,
          workspace: workspace,
          runtime_generation: runtime_generation,
          materialization_steps: pipeline_result.step_results
        )
      )
    end

    def materialization_pipeline
      MaterializationPipeline.new(
        session: session,
        operations: {
          create_project: lambda { |_outputs|
            project = create_project!
            session.project = project
            {project: project}
          },
          ensure_default_board: lambda { |outputs|
            {board: ensure_default_board!(outputs.fetch(:project))}
          },
          materialize_project_attributes: lambda { |outputs|
            {attribute_ids: materialize_project_attributes!(outputs.fetch(:project))}
          },
          write_setup_summary_document: lambda { |outputs|
            {document: write_setup_summary_document!(outputs.fetch(:project))}
          },
          initialize_project_protocols: lambda { |outputs|
            {protocol_generation: initialize_project_protocols!(outputs.fetch(:project))}
          },
          initialize_runtime_containers: lambda { |outputs|
            {runtime_generation: initialize_runtime_containers!(outputs.fetch(:project))}
          },
          ensure_starter_workflow_ticket: lambda { |outputs|
            {
              starter_ticket: ensure_starter_workflow_ticket!(
                project: outputs.fetch(:project),
                board: outputs.fetch(:board),
                document: outputs.fetch(:document)
              )
            }
          },
          ensure_runtime_containers_readiness_ticket: lambda { |outputs|
            {
              runtime_containers_readiness_ticket: ensure_runtime_containers_readiness_ticket!(
                project: outputs.fetch(:project),
                board: outputs.fetch(:board),
                document: outputs.fetch(:document),
                runtime_generation: outputs.fetch(:runtime_generation)
              )
            }
          },
          materialize_local_workspace: lambda { |outputs|
            {
              workspace: materialize_local_workspace(
                outputs.fetch(:project),
                starter_ticket: outputs[:starter_ticket],
                runtime_containers_readiness_ticket: outputs[:runtime_containers_readiness_ticket]
              )
            }
          },
          reconcile_starter_ticket_description: lambda { |outputs|
            reconcile_starter_ticket_description!(outputs[:starter_ticket], outputs.fetch(:project), outputs[:workspace])
            {}
          },
          reconcile_runtime_containers_readiness_ticket_description: lambda { |outputs|
            reconcile_runtime_containers_readiness_ticket_description!(
              outputs[:runtime_containers_readiness_ticket],
              outputs.fetch(:project),
              outputs.fetch(:runtime_generation)
            )
            {}
          },
          finalize_session_metadata: lambda { |outputs|
            finalize_session_metadata!(
              project: outputs.fetch(:project),
              board: outputs.fetch(:board),
              document: outputs.fetch(:document),
              starter_ticket: outputs[:starter_ticket],
              protocol_generation: outputs.fetch(:protocol_generation),
              runtime_containers_readiness_ticket: outputs[:runtime_containers_readiness_ticket],
              attribute_ids: outputs.fetch(:attribute_ids),
              workspace: outputs[:workspace],
              runtime_generation: outputs.fetch(:runtime_generation),
              materialization_steps: []
            )
            {}
          }
        }
      )
    end

    def context_turn_for_request(request_id)
      return nil if request_id.to_s.empty?

      turn = session.project_setup_turns.find_by(request_id: request_id.to_s)
      return nil unless turn
      return nil unless turn.normalized_fields["setup_context_action"].present?

      turn
    end

    def record_context_turn!(question:, answer:, normalized_fields:, source_channel:, request_id:)
      StateMachine.new(session: session).record_turn!(
        question: question,
        answer: answer,
        normalized_fields: normalized_fields,
        source_channel: source_channel,
        request_id: request_id
      )
    end

    def turn_fields(slot_key:, action:, normalized_fields:, value:, raw_value: nil, normalization_status: nil, normalization_reason: nil)
      normalized_fields.to_h.transform_keys(&:to_s).merge(
        "setup_context_slot" => slot_key,
        "setup_context_action" => action,
        "setup_context_value" => value,
        "setup_context_raw_value" => raw_value.nil? ? value : raw_value,
        "setup_context_normalization_status" => normalization_status.to_s,
        "setup_context_normalization_reason" => normalization_reason.to_s
      )
    end

    def turn_recorded_effect(turn)
      saga_effect("project_setup_turn_recorded", visibility: "internal", session_id: session.id, turn_index: turn.turn_index)
    end

    def current_slot_key
      intent = session.metadata["next_prompt_intent"]
      return nil unless intent.is_a?(Hash)

      slot = intent["slot"].to_s
      ProjectSetupSession::SETUP_SLOT_KEYS.include?(slot) ? slot : nil
    end

    def next_slot_key
      SLOT_ORDER.find { |slot_key| slot_missing?(slot_key) }
    end

    def missing_blocking_slot
      SLOT_ORDER.find { |slot_key| blocking_slot?(slot_key) && slot_missing?(slot_key) }
    end

    def slot_missing?(slot_key)
      slot = session.setup_slot(slot_key)
      return true unless slot.is_a?(Hash)
      return false if %w[filled defaulted skipped].include?(slot["status"].to_s)

      slot["value"].to_s.strip.empty?
    end

    def blocking_slot?(slot_key)
      ProjectSetupSession::SETUP_SLOT_REQUIREDNESS.fetch(slot_key) == "blocking"
    end

    def store_next_prompt_intent!(slot_key)
      metadata = session.metadata
      metadata["next_prompt_intent"] = PromptIntentBuilder.setup_slot(slot_key)
      session.metadata = metadata
      session.save!
    end

    def clear_next_prompt_intent!
      metadata = session.metadata
      metadata.delete("next_prompt_intent")
      session.metadata = metadata
      session.save!
    end

    def default_missing_slots!
      if slot_missing?("description")
        session.assign_setup_slot(
          key: "description",
          value: DEFAULT_DESCRIPTION,
          source: "default",
          status: "defaulted"
        )
      end
      if slot_missing?("stack")
        session.assign_setup_slot(
          key: "stack",
          value: stack_value_for_project,
          source: "default",
          status: "defaulted"
        )
      end
      assign_default_slot!("project_type", DEFAULT_PROJECT_TYPE)
      assign_default_slot!("language_runtime", DEFAULT_LANGUAGE_RUNTIME)
      assign_default_slot!("framework", DEFAULT_FRAMEWORK)
      assign_default_slot!("libraries", DEFAULT_LIBRARIES)
      assign_default_slot!("runtime_container_profile", DEFAULT_RUNTIME_CONTAINER_PROFILE)
      assign_default_slot!("agent_workflow_mode", DEFAULT_AGENT_WORKFLOW_MODE)
      clear_next_prompt_intent!
    end

    def assign_default_slot!(key, value)
      return unless slot_missing?(key)

      session.assign_setup_slot(
        key: key,
        value: value,
        source: "default",
        status: "defaulted"
      )
    end

    def normalize_answer(slot_key:, answer:, normalized_fields:)
      SemanticAnswerNormalizer.new.normalize(
        slot_key: slot_key,
        answer: answer,
        normalized_fields: normalized_fields,
        setup_context: session.setup_context
      )
    end

    def normalized_fields_from(normalization:, original_fields:)
      original_fields.to_h.transform_keys(&:to_s).merge(
        "semantic_normalization" => {
          "slot" => normalization.slot_key,
          "raw_value" => normalization.raw_value,
          "value" => normalization.value,
          "source" => normalization.source,
          "status" => normalization.status,
          "confidence" => normalization.confidence,
          "reason" => normalization.normalization_reason,
          "slot_updates" => normalization.slot_updates,
          "warnings" => normalization.warnings
        }
      )
    end

    def assign_auxiliary_normalized_slots!(current_slot_key:, normalized_fields:)
      normalized = normalized_fields.to_h.transform_keys(&:to_s)
      ProjectSetupSession::SETUP_SLOT_KEYS.each do |slot_key|
        next if slot_key == current_slot_key
        next unless normalized.key?(slot_key)

        value = normalized[slot_key]
        next if value.to_s.strip.empty?

        session.assign_setup_slot(
          key: slot_key,
          value: value,
          raw_value: value,
          source: "normalized_context",
          normalization_reason: "auxiliary semantic normalization"
        )
      end
    end

    def control_from(answer)
      normalized = answer.to_s.strip.downcase
      return "cancel" if %w[/cancel cancel].include?(normalized)
      return "done" if %w[/done done].include?(normalized)
      return "skip" if %w[/skip skip].include?(normalized)

      nil
    end

    def create_project!
      return session.project if session.project

      name = slot_value("project_name")
      directory_name = unique_directory_name(directory_name_from(name))
      repo_url = repository_url_for(directory_name)
      Project.create!(
        name: name,
        description: project_description_value,
        root_path: "/workspace/projects/#{directory_name}",
        repo_url: repo_url,
        stack_slug: stack_slug_from(stack_value_for_project)
      )
    end

    def ensure_default_board!(project)
      project_key = unique_project_key(directory_name_from(project.name))
      board = project.boards.find_or_initialize_by(name: "#{project.name} Board")
      board.project_key ||= project_key
      board.save!

      BOARD_COLUMNS.each_with_index do |(key, title), index|
        column = board.columns.find_or_initialize_by(key: key)
        column.title = title
        column.position = index
        column.save!
      end
      board
    end

    def materialize_project_attributes!(project)
      session.setup_slots.filter_map do |key, slot|
        value = slot["value"].to_s.strip
        next if value.empty?

        attribute = ProjectAttribute.find_or_initialize_by(
          project: project,
          key: "setup_context.#{key}"
        )
        attribute.value = value
        attribute.weight = materialized_weight(slot["weight"].presence || ProjectSetupSession::SETUP_SLOT_WEIGHTS.fetch(key, 1))
        attribute.source = SETUP_ATTRIBUTE_SOURCE
        attribute.save!
        attribute.id
      end
    end

    def materialized_weight(value)
      [[value.to_i, 1].max, 5].min
    end

    def write_setup_summary_document!(project)
      document = Document.find_or_initialize_by(
        project: project,
        artifact_type: "draft",
        title: SETUP_DOCUMENT_TITLE
      )
      document.body = setup_summary_body(project)
      document.editable = true
      document.save!
      document
    end

    def ensure_starter_workflow_ticket!(project:, board:, document:)
      column = board.columns.find_by!(key: "backlog")
      ticket = board.tickets.find_or_initialize_by(title: STARTER_TICKET_TITLE)
      ticket.column ||= column
      ticket.description = starter_ticket_description(project)
      ticket.priority = :high
      ticket.assignee ||= STARTER_TICKET_ASSIGNEE
      ticket.save!
      ticket
    end

    def initialize_runtime_containers!(project)
      RuntimeContainers::GenerationService.new(project: project).call
    end

    def initialize_project_protocols!(project)
      ProjectProtocols::InitializationService.new(project: project).call
    end

    def ensure_runtime_containers_readiness_ticket!(project:, board:, document:, runtime_generation:)
      runtime_container = project.reload.runtime_container
      return nil unless runtime_container
      return nil if runtime_container.readiness == "ready"

      column = board.columns.find_by!(key: "backlog")
      ticket = board.tickets.find_or_initialize_by(title: RUNTIME_CONTAINERS_READINESS_TICKET_TITLE)
      ticket.column ||= column
      ticket.description = runtime_containers_readiness_ticket_description(project, runtime_generation)
      ticket.priority = runtime_container.readiness == "blocked" ? :high : :medium
      ticket.assignee ||= STARTER_TICKET_ASSIGNEE
      ticket.save!
      ticket
    end

    def materialize_local_workspace(project, starter_ticket:, runtime_containers_readiness_ticket:)
      LocalWorkspaceMaterializer.new(
        session: session,
        project: project,
        starter_ticket: starter_ticket,
        runtime_containers_readiness_ticket: runtime_containers_readiness_ticket
      ).call
    end

    def reconcile_starter_ticket_description!(starter_ticket, project, workspace)
      return unless starter_ticket

      starter_ticket.description = starter_ticket_description(project, workspace: workspace)
      starter_ticket.save!
    end

    def reconcile_runtime_containers_readiness_ticket_description!(ticket, project, runtime_generation)
      return unless ticket

      ticket.description = runtime_containers_readiness_ticket_description(project, runtime_generation)
      ticket.save!
    end

    def starter_ticket_description(project, workspace: nil)
      materialization_status = workspace_value(workspace, "materialization_status", "materialized_planned")
      validation_status = workspace_value(workspace, "validation_status", "skipped")
      runnable = workspace_value(workspace, "runnable", false) == true ? "yes" : "no"
      scaffold_profile = workspace_value(workspace, "scaffold_profile", "")
      [
        "Use the project setup context to produce the initial implementation plan.",
        "Project: #{project.name}",
        "Materialization outcome: #{materialization_status}",
        "Initial implementation outcome: #{workspace_value(workspace, "initial_implementation_status", "planned")}",
        "Runnable now: #{runnable}",
        "Validation: #{validation_status}",
        ("Scaffold profile: #{scaffold_profile}" if scaffold_profile.present?),
        "Type: #{slot_value("project_type")}",
        "Language/runtime: #{slot_value("language_runtime")}",
        "Framework: #{slot_value("framework")}",
        "Libraries: #{slot_value("libraries")}",
        "Runtime container profile: #{slot_value("runtime_container_profile")}"
      ].compact.join("\n")
    end

    def runtime_containers_readiness_ticket_description(project, runtime_generation)
      state = project.reload.runtime_container_state
      missing_information = Array(state["missing_information"]).map { |item| "- #{item}" }
      risks = Array(state["risks"]).map do |risk|
        risk.is_a?(Hash) ? "- #{risk["severity"]}: #{risk["message"]}" : "- #{risk}"
      end

      [
        "Review and complete the project Runtime Containers configuration before sandbox-required ticket execution starts.",
        "Project: #{project.name}",
        "Runtime Containers profile: #{state["profile"]}",
        "Readiness: #{state["readiness"]}",
        "Validation: #{state["validation_status"]}",
        "Generator source: #{runtime_generation&.generator_source}",
        "Validation command: #{state["validation_command"]}",
        ("Missing information:\n#{missing_information.join("\n")}" if missing_information.any?),
        ("Risks:\n#{risks.join("\n")}" if risks.any?)
      ].compact.join("\n")
    end

    def workspace_value(workspace, key, fallback)
      return fallback unless workspace.is_a?(Hash)

      workspace.key?(key) ? workspace[key] : fallback
    end

    def setup_summary_body(project)
      lines = [
        "# Project Setup Summary",
        "",
        "- Project: #{project.name}",
        "- Stack: #{project.stack_slug}",
        "- Repository: #{project.repo_url}",
        "",
        "## Canonical Slots"
      ]
      session.setup_slots.each_value do |slot|
        lines << "- #{slot.fetch("key")}: #{slot["value"]} (#{slot["status"]})"
      end
      lines.join("\n")
    end

    def finalize_session_metadata!(project:, board:, document:, starter_ticket:, protocol_generation:, runtime_containers_readiness_ticket:, attribute_ids:, workspace:, runtime_generation:, materialization_steps:)
      metadata = session.metadata
      metadata["project_id"] = project.id
      metadata["board_id"] = board.id
      metadata["setup_summary_document_id"] = document.id
      metadata["starter_ticket_id"] = starter_ticket&.id if starter_ticket
      metadata["protocols_generation"] = protocol_generation_metadata(protocol_generation)
      metadata["protocols"] = project.reload.protocol_state.except("documents")
      metadata["runtime_containers_readiness_ticket_id"] = runtime_containers_readiness_ticket&.id if runtime_containers_readiness_ticket
      metadata["runtime_containers_generation"] = runtime_generation_metadata(runtime_generation)
      metadata["runtime_containers"] = project.reload.runtime_container_state
      metadata["setup_project_attribute_ids"] = attribute_ids
      metadata["guided_alignment_pending"] = false
      metadata["repository_placeholder"] = project.repo_url if repository_slot_missing?
      metadata["materialized_setup_context"] = session.setup_context
      metadata["materialized_project"] = project_data(project)
      metadata["materialized_repository_url"] = project.repo_url
      metadata["setup_completion_materialized"] = true
      metadata["setup_completion_materialized_at"] ||= Time.current.iso8601
      metadata["workspace"] = workspace if workspace
      metadata["materialization_steps"] = Array(materialization_steps)
      session.metadata = metadata
      session.save!
    end

    def persist_materialization_steps!(step_results)
      metadata = session.metadata
      metadata["materialization_steps"] = Array(step_results).map do |step_result|
        step_result.to_h.merge("visibility" => "debug")
      end
      session.metadata = metadata
      session.save!
    end

    def runtime_generation_metadata(runtime_generation)
      return {} unless runtime_generation

      {
        "persisted" => runtime_generation.persisted?,
        "generator_source" => runtime_generation.generator_source,
        "fallback_reason" => runtime_generation.fallback_reason,
        "errors" => runtime_generation.errors
      }
    end

    def protocol_generation_metadata(protocol_generation)
      return {} unless protocol_generation

      {
        "initialized" => protocol_generation.fetch("initialized"),
        "stack_keys" => protocol_generation.fetch("stack_keys"),
        "fallback_used" => protocol_generation.fetch("fallback_used"),
        "missing_stack_tokens" => protocol_generation.fetch("missing_stack_tokens")
      }
    end

    def materialization_data(project:, board:, document:, starter_ticket:, protocol_generation:, runtime_containers_readiness_ticket:, attribute_ids:, workspace:, runtime_generation:, materialization_steps:)
      data = {
        "project" => project_data(project),
        "board_id" => board.id,
        "setup_summary_document_id" => document.id,
        "starter_ticket_id" => starter_ticket&.id,
        "protocols" => project.reload.protocol_state,
        "protocols_generation" => protocol_generation_metadata(protocol_generation),
        "runtime_containers_readiness_ticket_id" => runtime_containers_readiness_ticket&.id,
        "runtime_containers" => project.reload.runtime_container_state,
        "runtime_containers_generation" => runtime_generation_metadata(runtime_generation),
        "setup_project_attribute_ids" => attribute_ids,
        "materialization_steps" => materialization_steps
      }
      data["workspace"] = workspace if workspace
      data
    end

    def completion_materialization_data
      metadata = session.metadata
      project = session.project
      return {} unless project
      return {} unless metadata["setup_completion_materialized"] == true

      data = {
        "project" => metadata["materialized_project"] || project_data(project),
        "board_id" => metadata["board_id"],
        "setup_summary_document_id" => metadata["setup_summary_document_id"],
        "starter_ticket_id" => metadata["starter_ticket_id"],
        "protocols" => project.protocol_state,
        "protocols_generation" => metadata["protocols_generation"] || {},
        "runtime_containers_readiness_ticket_id" => metadata["runtime_containers_readiness_ticket_id"],
        "runtime_containers" => metadata["runtime_containers"] || project.runtime_container_state,
        "runtime_containers_generation" => metadata["runtime_containers_generation"] || {},
        "setup_project_attribute_ids" => metadata["setup_project_attribute_ids"] || [],
        "materialization_steps" => metadata["materialization_steps"] || []
      }
      data["workspace"] = metadata["workspace"] if metadata["workspace"].is_a?(Hash)
      data
    end

    def completion_materialized?
      session.metadata["setup_completion_materialized"] == true && session.project_id.present?
    end

    def completion_reused_effect
      saga_effect("project_setup_completion_reused", visibility: "internal", session_id: session.id, project_id: session.project_id)
    end

    def saga_effect(type, visibility:, **data)
      HeavyInteractionSagas::Effect.new(type: type, visibility: visibility, data: data).to_h
    end

    def repository_url_for(directory_name)
      repository = slot_value("repository")
      return repository unless repository.empty?

      "local://redwright/projects/#{directory_name}"
    end

    def project_description_value
      description = slot_value("description")
      description.empty? ? DEFAULT_DESCRIPTION : description
    end

    def repository_slot_missing?
      slot_value("repository").empty?
    end

    def agent_workflow_requested?
      normalized = slot_value("agent_workflow_mode").downcase
      return false if normalized.empty?
      return false if %w[manual none no disabled off false].include?(normalized)

      normalized.match?(/agent|auto|workflow|ticket|start|execute|enabled|yes|true/)
    end

    def stack_value_for_project
      framework = slot_value("framework")
      return framework if usable_stack_value?(framework)

      language_runtime = slot_value("language_runtime")
      return language_runtime unless language_runtime.empty? || language_runtime == DEFAULT_LANGUAGE_RUNTIME

      legacy_stack = slot_value("stack")
      return legacy_stack unless legacy_stack.empty?

      DEFAULT_STACK
    end

    def usable_stack_value?(value)
      return false if value.empty? || none_like?(value) || value == DEFAULT_FRAMEWORK

      !value.match?(/understand|confusing|unclear/i)
    end

    def none_like?(value)
      %w[none no n/a not-applicable].include?(value.to_s.strip.downcase)
    end

    def slot_value(key)
      slot = session.setup_slot(key)
      return "" unless slot.is_a?(Hash)

      slot["value"].to_s.strip
    end

    def directory_name_from(value)
      normalized = value.to_s.downcase.gsub(/[^a-z0-9._-]+/, "-").gsub(/\A-+|-+\z/, "")
      normalized.empty? ? "project-#{session.id}" : normalized
    end

    def stack_slug_from(value)
      slug = directory_name_from(value)
      slug.empty? ? DEFAULT_STACK : slug
    end

    def unique_directory_name(base)
      candidate = base
      return candidate unless Project.exists?(root_path: "/workspace/projects/#{candidate}")

      "#{base}-#{session.id}"
    end

    def unique_project_key(base)
      candidate = base
      return candidate unless Board.exists?(project_key: candidate)

      "#{base}-#{session.id}"
    end

    def project_data(project)
      {
        "id" => project.id,
        "name" => project.name,
        "description" => project.description,
        "root_path" => project.root_path,
        "repo_url" => project.repo_url,
        "stack_slug" => project.stack_slug,
        "protocols" => project.protocol_state
      }
    end

    def summary_for(session)
      return "Project setup cancelled." if session.current_state == "cancelled"
      return "Project created; setup completed." if session.current_state == "completed"

      "Project setup context updated."
    end

    def success(turn:, summary:, effects:, data: {})
      Result.new(ok: true, session: session.reload, turn: turn, summary: summary, effects: effects, errors: [], data: data)
    end

    def failure(code:, message:)
      Result.new(
        ok: false,
        session: session,
        turn: nil,
        summary: "Project setup context could not be advanced.",
        effects: [],
        errors: [
          {
            code: code,
            message: message,
            details: []
          }
        ],
        data: {}
      )
    end
  end
end
