module AgentTicketExecution
  class ValidationExecutor
    def initialize(validation_loop:)
      @validation_loop = validation_loop
    end

    def call(request:, ticket:, workspace:, execution_context: nil)
      result = validation_loop.call(request: request, ticket: ticket, workspace: workspace)
      result.to_execution.merge(
        "acknowledgement" => {
          "status" => result.state,
          "message" => result.completed? ? "Agent ticket execution completed." : "Agent ticket execution blocked.",
          "request_id" => request.fetch("request_id"),
          "ticket_id" => ticket.id,
          "mode" => request.fetch("mode")
        }
      )
    end

    private

    attr_reader :validation_loop
  end
end
