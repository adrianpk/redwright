module ProjectSetup
  class SagaState
    KEY = "setup_saga".freeze
    VERSION = 1

    QUESTIONNAIRE_STATES = %w[
      collecting_context
      awaiting_repository
      awaiting_repository_confirmation
      awaiting_alignment_opt_in
      collecting_alignment
    ].freeze

    MATERIALIZATION_STATES = %w[
      ready_to_create
      creating_project
    ].freeze

    def self.snapshot(session)
      new(session: session).snapshot
    end

    def initialize(session:)
      @session = session
    end

    def snapshot
      state = deep_merge(default_state, persisted_state)
      state["version"] = VERSION
      state["current_state"] = session.current_state
      state["session_id"] = session.id
      state["project_id"] = session.project_id
      state["stage"] = persisted_state["stage"].presence || inferred_stage
      state["status"] = persisted_state["status"].presence || inferred_status
      state["questionnaire"] = questionnaire_state(state["questionnaire"])
      state
    end

    def mark_questionnaire!(status: "collecting")
      write!(
        "stage" => "questionnaire",
        "status" => status,
        "questionnaire" => {
          "status" => status,
          "turn_counter" => session.turn_counter.to_i,
          "next_prompt_intent" => next_prompt_intent
        }
      )
    end

    def mark_materialization_started!
      write!(
        "stage" => "materialization",
        "status" => "running",
        "questionnaire" => {
          "status" => "completed",
          "turn_counter" => session.turn_counter.to_i
        },
        "materialization" => {
          "status" => "running",
          "started_at" => Time.current.iso8601
        }
      )
    end

    def mark_materialized!(project:, workspace: {})
      write!(
        "materialization" => {
          "status" => "materialized",
          "project_id" => project.id,
          "workspace" => workspace || {},
          "completed_at" => Time.current.iso8601
        }
      )
    end

    def mark_completed!(project:, board:, document:, starter_ticket:, attribute_ids:, workspace:)
      write!(
        "stage" => "ticket_operation",
        "status" => "ready",
        "questionnaire" => {
          "status" => "completed",
          "turn_counter" => session.turn_counter.to_i
        },
        "materialization" => {
          "status" => materialization_status_from(workspace),
          "project_id" => project.id,
          "board_id" => board&.id,
          "setup_summary_document_id" => document&.id,
          "setup_project_attribute_ids" => attribute_ids,
          "workspace" => workspace || {},
          "validation_status" => value_from(workspace, "validation_status", "not_run"),
          "validation" => value_from(workspace, "validation", {}),
          "runnable" => value_from(workspace, "runnable", false),
          "reason" => value_from(workspace, "reason", ""),
          "completed_at" => Time.current.iso8601
        },
        "initial_implementation" => {
          "status" => value_from(workspace, "initial_implementation_status", "planned"),
          "runnable" => value_from(workspace, "runnable", false),
          "reason" => value_from(workspace, "reason", ""),
          "linked_ticket_ids" => linked_ticket_ids_from(workspace, starter_ticket)
        },
        "protocols" => protocols_state_from(project),
        "runtime_containers" => runtime_containers_state_from(workspace),
        "ticket_operation" => {
          "status" => "available",
          "project_id" => project.id,
          "board_id" => board&.id,
          "starter_ticket_id" => starter_ticket&.id,
          "linked_ticket_ids" => linked_ticket_ids_from(workspace, starter_ticket),
          "open_ticket_count" => project.tickets_scope.active.count
        }
      )
    end

    def mark_cancelled!
      write!(
        "stage" => "cancelled",
        "status" => "cancelled",
        "questionnaire" => {
          "status" => "cancelled",
          "turn_counter" => session.turn_counter.to_i
        }
      )
    end

    def mark_failed!(reason:)
      write!(
        "stage" => "failed",
        "status" => "failed",
        "materialization" => {
          "status" => "failed",
          "reason" => reason.to_s
        }
      )
    end

    private

    attr_reader :session

    def write!(updates)
      metadata = session.metadata
      next_state = deep_merge(snapshot, updates)
      next_state["version"] = VERSION
      next_state["current_state"] = session.current_state
      next_state["session_id"] = session.id
      next_state["project_id"] = session.project_id
      next_state["updated_at"] = Time.current.iso8601
      metadata[KEY] = next_state
      session.metadata = metadata
      session.save!
      next_state
    end

    def persisted_state
      state = session.metadata[KEY]
      state.is_a?(Hash) ? stringify_hash(state) : {}
    end

    def default_state
      {
        "version" => VERSION,
        "stage" => inferred_stage,
        "status" => inferred_status,
        "current_state" => session.current_state,
        "session_id" => session.id,
        "project_id" => session.project_id,
        "updated_at" => nil,
        "questionnaire" => {
          "status" => questionnaire_status,
          "turn_counter" => session.turn_counter.to_i,
          "next_prompt_intent" => next_prompt_intent
        },
        "materialization" => {
          "status" => materialization_status
        },
        "initial_implementation" => {
          "status" => "pending",
          "runnable" => false,
          "reason" => "initial implementation has not started"
        },
        "protocols" => {
          "status" => "pending"
        },
        "runtime_containers" => {
          "status" => "pending"
        },
        "ticket_operation" => {
          "status" => ticket_operation_status
        }
      }
    end

    def questionnaire_state(existing)
      current = existing.is_a?(Hash) ? existing : {}
      current.merge(
        "turn_counter" => session.turn_counter.to_i,
        "next_prompt_intent" => next_prompt_intent
      )
    end

    def inferred_stage
      state = session.current_state.to_s
      return "questionnaire" if QUESTIONNAIRE_STATES.include?(state)
      return "materialization" if MATERIALIZATION_STATES.include?(state)
      return "ticket_operation" if state == "completed"
      return "cancelled" if state == "cancelled"
      return "failed" if %w[failed needs_reconciliation].include?(state)

      "questionnaire"
    end

    def inferred_status
      case session.current_state.to_s
      when "completed"
        "ready"
      when "cancelled"
        "cancelled"
      when "failed", "needs_reconciliation"
        "failed"
      when "ready_to_create", "creating_project"
        "running"
      else
        "collecting"
      end
    end

    def questionnaire_status
      return "completed" if session.current_state == "completed"
      return "cancelled" if session.current_state == "cancelled"

      QUESTIONNAIRE_STATES.include?(session.current_state.to_s) ? "collecting" : "completed"
    end

    def materialization_status
      return "materialized" if session.metadata["setup_completion_materialized"] == true
      return "running" if MATERIALIZATION_STATES.include?(session.current_state.to_s)

      "pending"
    end

    def ticket_operation_status
      session.current_state == "completed" && session.project_id.present? ? "available" : "pending"
    end

    def next_prompt_intent
      intent = session.metadata["next_prompt_intent"]
      intent.is_a?(Hash) ? stringify_hash(intent) : {}
    end

    def materialization_status_from(workspace)
      value_from(workspace, "materialization_status", "materialized")
    end

    def linked_ticket_ids_from(workspace, starter_ticket)
      ids = value_from(workspace, "linked_ticket_ids", [])
      ids = [] unless ids.is_a?(Array)
      ids << starter_ticket.id if starter_ticket && !ids.include?(starter_ticket.id)
      ids
    end

    def runtime_containers_state_from(workspace)
      state = value_from(workspace, "runtime_containers", {})
      state = {} unless state.is_a?(Hash)

      {
        "status" => state["status"].presence || "missing",
        "id" => state["id"],
        "readiness" => state["readiness"].presence || "missing",
        "validation_status" => state["validation_status"].presence || "not_run",
        "profile" => state["profile"].presence || "default",
        "readiness_ticket_id" => value_from(workspace, "runtime_containers_readiness_ticket_id", nil)
      }
    end

    def protocols_state_from(project)
      state = project.protocol_state

      {
        "status" => state["status"].presence || "missing",
        "id" => state["id"],
        "document_count" => Array(state["documents"]).size
      }
    end

    def value_from(hash, key, fallback)
      return fallback unless hash.is_a?(Hash)

      hash.key?(key) ? hash[key] : fallback
    end

    def deep_merge(left, right)
      left.merge(right) do |_key, left_value, right_value|
        if left_value.is_a?(Hash) && right_value.is_a?(Hash)
          deep_merge(left_value, right_value)
        else
          right_value
        end
      end
    end

    def stringify_hash(value)
      value.to_h.transform_keys(&:to_s)
    end
  end
end
