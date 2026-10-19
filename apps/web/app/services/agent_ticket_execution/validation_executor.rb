module AgentTicketExecution
  class ValidationExecutor
    def initialize(validation_loop:, git_finalizer: nil)
      @validation_loop = validation_loop
      @git_finalizer = git_finalizer
    end

    def call(request:, ticket:, workspace:, execution_context: nil)
      outcome = validation_loop.with_operation(request: request, ticket: ticket, workspace: workspace) do |scoped|
        execute(scoped, request: request, ticket: ticket, workspace: scoped.workspace_for(workspace))
      end
      outcome.respond_to?(:to_execution) ? outcome.to_execution : outcome
    end

    private

    def execute(loop, request:, ticket:, workspace:)
      result = loop.call(request: request, ticket: ticket, workspace: workspace)
      execution = result.to_execution.merge(
        "acknowledgement" => {
          "status" => result.state,
          "message" => result.completed? ? "Agent ticket execution completed." : "Agent ticket execution blocked.",
          "request_id" => request.fetch("request_id"),
          "ticket_id" => ticket.id,
          "ticket_ref" => ticket.display_key,
          "ticket_key" => ticket.ticket_key,
          "mode" => request.fetch("mode")
        }
      )
      return execution unless result.completed? && git_finalizer

      git_result = loop.finalize do
        git_finalizer.finalize(ticket: ticket, request: request, workspace: workspace, validation_result: result)
      end
      execution.fetch("details")["git"] = git_result.to_h
      unless git_result.ok?
        execution["state"] = "blocked"
        execution["terminal_outcome"] = {
          "status" => "blocked",
          "ticket_id" => ticket.id,
          "ticket_ref" => ticket.display_key,
          "ticket_key" => ticket.ticket_key,
          "code" => git_result.code,
          "reason" => git_result.message
        }
        execution.fetch("acknowledgement")["status"] = "blocked"
        execution.fetch("acknowledgement")["message"] = "Agent ticket execution blocked."
      end
      execution
    end

    private

    attr_reader :validation_loop
    attr_reader :git_finalizer
  end
end
