module AgentTicketExecution
  class ResponsePresenter
    def present(result:, request_id:)
      CommandQuery::Result.ok(
        request_id: request_id,
        data: execution_data(result),
        effects: execution_effects(result)
      )
    end

    private

    def execution_data(result)
      request = result.request
      ticket = result.ticket
      board = result.board
      workspace = result.workspace
      execution_context = result.execution_context
      execution = result.execution

      {
        "summary" => summary_for(execution),
        "execution" => {
          "command" => RequestBuilder::COMMAND_NAME,
          "mode" => request.fetch("mode"),
          "state" => execution.fetch("state"),
          "ticket_id" => ticket&.id || request.fetch("ticket_id"),
          "ticket_ref" => ticket&.display_key || request.fetch("ticket_ref"),
          "ticket_key" => ticket&.ticket_key,
          "project_id" => ticket&.project_id || board&.project_id || request.fetch("project_id"),
          "board_id" => ticket&.board_id || board&.id || request.fetch("board_id"),
          "assignee" => request.fetch("assignee"),
          "workspace" => workspace&.context,
          "context" => execution_context&.diagnostics,
          "acknowledgement" => execution.fetch("acknowledgement"),
          "terminal_outcome" => execution.fetch("terminal_outcome"),
          "details" => execution.fetch("details")
        }
      }
    end

    def execution_effects(result)
      request = result.request
      ticket = result.ticket
      board = result.board
      execution = result.execution

      [
        {
          "type" => "agent_ticket_execution_#{execution.fetch("state")}",
          "mode" => request.fetch("mode"),
          "ticket_id" => ticket&.id || request.fetch("ticket_id"),
          "ticket_ref" => ticket&.display_key || request.fetch("ticket_ref"),
          "ticket_key" => ticket&.ticket_key,
          "project_id" => ticket&.project_id || board&.project_id || request.fetch("project_id"),
          "board_id" => ticket&.board_id || board&.id || request.fetch("board_id")
        }
      ]
    end

    def summary_for(execution)
      return "Agent ticket execution completed." if execution.fetch("terminal_outcome").present?

      "Agent ticket execution accepted."
    end
  end
end
