module AgentTicketExecution
  class Runner
    Result = Struct.new(:request, :board, :ticket, :workspace, :execution_context, :execution, keyword_init: true)

    def initialize(executor:, selection_policy: nil, workspace_boundary: nil, context_composer: nil, kanban_transitioner: KanbanTransitioner.new)
      @executor = executor
      @selection_policy = selection_policy
      @workspace_boundary = workspace_boundary
      @context_composer = context_composer
      @kanban_transitioner = kanban_transitioner
    end

    def call(request:)
      board = request.fetch("board_id").present? ? Board.find_by(id: request.fetch("board_id")) : nil
      selection = select_ticket(request: request, board: board)
      return selection unless selection.ok?

      ticket = selection.ticket
      workspace = resolve_workspace(request: request, ticket: ticket)
      return workspace if workspace && !workspace.ok?

      start_transition = kanban_transitioner.mark_started(ticket: ticket)
      execution_context = compose_execution_context(request: request, ticket: ticket, workspace: workspace)
      execution = normalize_execution(
        executor.call(
          request: request,
          ticket: ticket,
          workspace: workspace,
          execution_context: execution_context
        )
      )
      terminal_transition = kanban_transitioner.apply_terminal_outcome(ticket: ticket, execution: execution)
      execution.fetch("details")["kanban"] = {
        "start" => start_transition.to_h,
        "terminal" => terminal_transition.to_h
      }

      Result.new(
        request: request,
        board: board,
        ticket: ticket,
        workspace: workspace,
        execution_context: execution_context,
        execution: execution
      )
    end

    private

    attr_reader :executor, :selection_policy, :workspace_boundary, :context_composer, :kanban_transitioner

    def select_ticket(request:, board:)
      policy = selection_policy || TicketSelectionPolicy.new(admin_assignee: request.fetch("admin_assignee"))
      if request.fetch("mode") == "targeted"
        return policy.select_targeted(ticket: Ticket.resolve_ref(request.fetch("ticket_ref")))
      end

      policy.pick(
        board: board,
        project_id: request.fetch("project_id"),
        assignee: request.fetch("assignee")
      )
    end

    def resolve_workspace(request:, ticket:)
      return nil unless workspace_boundary

      workspace_boundary.resolve(ticket: ticket, branch_name: request["branch_name"])
    end

    def compose_execution_context(request:, ticket:, workspace:)
      return nil unless context_composer

      context_composer.compose(ticket: ticket, request: request, workspace: workspace)
    end

    def normalize_execution(raw)
      execution = raw.is_a?(Hash) ? raw : {}
      state = execution.fetch("state", "accepted").to_s

      {
        "state" => state,
        "acknowledgement" => execution.fetch("acknowledgement", acknowledgement_payload(state: state)),
        "terminal_outcome" => execution["terminal_outcome"],
        "details" => execution.fetch("details", {})
      }
    end

    def acknowledgement_payload(state:)
      {
        "status" => state,
        "message" => "Agent ticket execution accepted."
      }
    end
  end
end
