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

      success(
        turn: turn,
        summary: summary_for(session),
        effects: [
          {
            "type" => "project_setup_turn_reused",
            "session_id" => session.id,
            "turn_index" => turn.turn_index
          }
        ]
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
          result = success(
            turn: repeated,
            summary: summary_for(session),
            effects: [
              {
                "type" => "project_setup_turn_reused",
                "session_id" => session.id,
                "turn_index" => repeated.turn_index
              }
            ]
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

      turn = record_context_turn!(
        question: "setup_slot:#{slot_key}",
        answer: answer,
        normalized_fields: turn_fields(
          slot_key: slot_key,
          action: "answer",
          normalized_fields: normalized_fields,
          value: normalized_slot_value(slot_key: slot_key, answer: answer, normalized_fields: normalized_fields)
        ),
        source_channel: source_channel,
        request_id: request_id
      )
      session.assign_setup_slot(
        key: slot_key,
        value: normalized_slot_value(slot_key: slot_key, answer: answer, normalized_fields: normalized_fields),
        source: "user_answer"
      )
      assign_auxiliary_normalized_slots!(current_slot_key: slot_key, normalized_fields: normalized_fields)
      session.save!

      next_slot = next_slot_key
      return complete_setup!(turn: turn) unless next_slot

      store_next_prompt_intent!(next_slot)
      success(
        turn: turn,
        summary: "Project setup context updated.",
        effects: [
          turn_recorded_effect(turn),
          {
            "type" => "project_setup_prompt_advanced",
            "session_id" => session.id,
            "slot" => next_slot
          }
        ]
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
        return success(
          turn: turn,
          summary: "Project setup still needs a project name.",
          effects: [
            turn_recorded_effect(turn),
            {
              "type" => "project_setup_prompt_repeated",
              "session_id" => session.id,
              "slot" => slot_key
            }
          ]
        )
      end

      session.assign_setup_slot(key: slot_key, value: "", source: "user_control", status: "skipped")
      session.save!

      next_slot = next_slot_key
      return complete_setup!(turn: turn) unless next_slot

      store_next_prompt_intent!(next_slot)
      success(
        turn: turn,
        summary: "Project setup slot skipped.",
        effects: [
          turn_recorded_effect(turn),
          {
            "type" => "project_setup_prompt_advanced",
            "session_id" => session.id,
            "slot" => next_slot
          }
        ]
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
        return success(
          turn: turn,
          summary: "Project setup still needs a project name.",
          effects: [
            turn_recorded_effect(turn),
            {
              "type" => "project_setup_prompt_repeated",
              "session_id" => session.id,
              "slot" => missing
            }
          ]
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

      success(
        turn: turn,
        summary: "Project setup cancelled.",
        effects: [
          turn_recorded_effect(turn),
          {
            "type" => "project_setup_cancelled",
            "session_id" => session.id
          }
        ]
      )
    end

    def complete_setup!(turn:)
      default_missing_slots!

      project = nil
      board = nil
      document = nil
      starter_ticket = nil
      attribute_ids = []
      StateMachine.new(session: session).transition_to!("ready_to_create")
      StateMachine.new(session: session).transition_to!("creating_project")

      project = create_project!
      session.project = project
      board = ensure_default_board!(project)
      attribute_ids = materialize_project_attributes!(project)
      document = write_setup_summary_document!(project)
      starter_ticket = ensure_starter_workflow_ticket!(project: project, board: board, document: document)
      finalize_session_metadata!(
        project: project,
        board: board,
        document: document,
        starter_ticket: starter_ticket,
        attribute_ids: attribute_ids
      )
      StateMachine.new(session: session).transition_to!("completed", terminal_reason: "completed_without_alignment")

      effects = []
      effects << turn_recorded_effect(turn) if turn
      effects.concat(
        [
          {
            "type" => "project_created",
            "project_id" => project.id
          },
          {
            "type" => "setup_context_materialized",
            "session_id" => session.id,
            "project_id" => project.id,
            "project_attribute_ids" => attribute_ids
          },
          {
            "type" => "setup_summary_document_written",
            "session_id" => session.id,
            "project_id" => project.id,
            "document_id" => document.id
          },
          {
            "type" => "default_board_structure_written",
            "session_id" => session.id,
            "project_id" => project.id,
            "board_id" => board.id
          }
        ]
      )
      if starter_ticket
        effects << {
          "type" => "setup_starter_ticket_written",
          "session_id" => session.id,
          "project_id" => project.id,
          "board_id" => board.id,
          "ticket_id" => starter_ticket.id
        }
      end
      effects.concat(
        [
          {
            "type" => "project_setup_completed",
            "session_id" => session.id,
            "terminal_reason" => "completed_without_alignment"
          }
        ]
      )

      success(
        turn: turn,
        summary: "Project created; setup completed.",
        effects: effects,
        data: {
          "project" => project_data(project),
          "board_id" => board.id,
          "setup_summary_document_id" => document.id,
          "starter_ticket_id" => starter_ticket&.id,
          "setup_project_attribute_ids" => attribute_ids
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

    def turn_fields(slot_key:, action:, normalized_fields:, value:)
      normalized_fields.to_h.transform_keys(&:to_s).merge(
        "setup_context_slot" => slot_key,
        "setup_context_action" => action,
        "setup_context_value" => value
      )
    end

    def turn_recorded_effect(turn)
      {
        "type" => "project_setup_turn_recorded",
        "session_id" => session.id,
        "turn_index" => turn.turn_index
      }
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
      metadata["next_prompt_intent"] = {
        "kind" => "setup_slot_question",
        "slot" => slot_key,
        "locale" => "auto",
        "llm_required" => true
      }
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

    def normalized_slot_value(slot_key:, answer:, normalized_fields:)
      normalized = normalized_fields.to_h.transform_keys(&:to_s)
      value = normalized[slot_key]
      value = normalized["value"] if value.to_s.strip.empty?
      value.to_s.strip.empty? ? answer : value
    end

    def assign_auxiliary_normalized_slots!(current_slot_key:, normalized_fields:)
      normalized = normalized_fields.to_h.transform_keys(&:to_s)
      ProjectSetupSession::SETUP_SLOT_KEYS.each do |slot_key|
        next if slot_key == current_slot_key
        next unless normalized.key?(slot_key)

        value = normalized[slot_key]
        next if value.to_s.strip.empty?

        session.assign_setup_slot(key: slot_key, value: value, source: "normalized_context")
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
      name = slot_value("project_name")
      directory_name = unique_directory_name(directory_name_from(name))
      repo_url = repository_url_for(directory_name)
      Project.create!(
        name: name,
        description: slot_value("description"),
        root_path: "/workspace/projects/#{directory_name}",
        repo_url: repo_url,
        stack_slug: stack_slug_from(stack_value_for_project)
      )
    end

    def ensure_default_board!(project)
      project_key = unique_project_key(directory_name_from(project.name))
      board = Board.create!(
        project: project,
        name: "#{project.name} Board",
        project_key: project_key
      )
      BOARD_COLUMNS.each_with_index do |(key, title), index|
        board.columns.create!(key: key, title: title, position: index)
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
      return nil unless agent_workflow_requested?

      column = board.columns.find_by!(key: "backlog")
      ticket = board.tickets.find_or_initialize_by(title: STARTER_TICKET_TITLE)
      ticket.column ||= column
      ticket.description = starter_ticket_description(project)
      ticket.priority = :high
      ticket.assignee ||= STARTER_TICKET_ASSIGNEE
      ticket.save!

      link = ticket.ticket_document_links.find_or_initialize_by(document: document)
      link.role = "reference"
      link.save!
      ticket
    end

    def starter_ticket_description(project)
      [
        "Use the project setup context to produce the initial implementation plan.",
        "Project: #{project.name}",
        "Type: #{slot_value("project_type")}",
        "Language/runtime: #{slot_value("language_runtime")}",
        "Framework: #{slot_value("framework")}",
        "Libraries: #{slot_value("libraries")}",
        "Runtime container profile: #{slot_value("runtime_container_profile")}"
      ].join("\n")
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

    def finalize_session_metadata!(project:, board:, document:, starter_ticket:, attribute_ids:)
      metadata = session.metadata
      metadata["project_id"] = project.id
      metadata["board_id"] = board.id
      metadata["setup_summary_document_id"] = document.id
      metadata["starter_ticket_id"] = starter_ticket&.id if starter_ticket
      metadata["setup_project_attribute_ids"] = attribute_ids
      metadata["guided_alignment_pending"] = false
      metadata["repository_placeholder"] = project.repo_url if repository_slot_missing?
      session.metadata = metadata
      session.save!
    end

    def repository_url_for(directory_name)
      repository = slot_value("repository")
      return repository unless repository.empty?

      "local://redwright/projects/#{directory_name}"
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
      return framework unless framework.empty? || none_like?(framework) || framework == DEFAULT_FRAMEWORK

      language_runtime = slot_value("language_runtime")
      return language_runtime unless language_runtime.empty? || language_runtime == DEFAULT_LANGUAGE_RUNTIME

      legacy_stack = slot_value("stack")
      return legacy_stack unless legacy_stack.empty?

      DEFAULT_STACK
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
        "stack_slug" => project.stack_slug
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
