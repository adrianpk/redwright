module AgentTicketExecution
  class RequestBuilder
    include CommandQuery::PayloadReader

    COMMAND_NAME = "ExecuteAgentTicket".freeze
    MODES = %w[targeted pickup].freeze

    def build(payload:, context:, request_id:)
      ticket_ref = value_from(payload, "ticket_ref", "ticket_id").presence
      mode = value_from(payload, "mode").presence || (ticket_ref.present? ? "targeted" : "pickup")
      mode = mode.to_s
      return {"error" => "mode must be one of: #{MODES.join(", ")}"} unless MODES.include?(mode)
      return {"error" => "ticket_ref is required for targeted execution"} if mode == "targeted" && ticket_ref.blank?
      return {"error" => "project_id or board_id is required for pickup execution"} if mode == "pickup" && value_from(payload, "project_id", "board_id").blank?

      {
        "command" => COMMAND_NAME,
        "request_id" => request_id.to_s,
        "mode" => mode,
        "ticket_ref" => ticket_ref.to_s.presence,
        "ticket_id" => ticket_ref.to_s.match?(/\A\d+\z/) ? ticket_ref.to_i : nil,
        "project_id" => value_from(payload, "project_id")&.to_i,
        "board_id" => value_from(payload, "board_id")&.to_i,
        "assignee" => value_from(payload, "assignee").to_s.presence,
        "admin_assignee" => value_from(payload, "admin_assignee").to_s.presence,
        "branch_name" => value_from(payload, "branch_name").to_s.presence,
        "session_id" => value_from(payload, "session_id").to_s.presence,
        "agent_id" => value_from(payload, "agent_id").to_s.presence,
        "trace_id" => value_from(context, "trace_id").to_s.presence,
        "actor_identifier" => actor_identifier_from(context),
        "source_channel" => value_from(context, "source_channel").to_s.presence || "unknown",
        "loop" => {
          "enabled" => truthy?(value_from(payload, "loop")),
          "max_tickets" => integer_value(value_from(payload, "max_tickets"), default: 1)
        }
      }
    end

    private

    def truthy?(value)
      value == true || value.to_s == "true" || value.to_s == "1"
    end

    def integer_value(value, default:)
      Integer(value.presence || default)
    rescue ArgumentError, TypeError
      default
    end

    def actor_identifier_from(context)
      value_from(context, "actor_identifier").to_s.presence || "unknown"
    end
  end
end
