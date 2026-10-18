module AgentTicketExecution
  class TicketSelectionPolicy
    DEVELOPMENT_COLUMN_KEYS = %w[backlog open ready].freeze
    DEVELOPMENT_WORKFLOW_STATUSES = %w[open ready].freeze

    Result = Struct.new(:ok, :ticket, :code, :message, keyword_init: true) do
      def ok?
        ok == true
      end
    end

    def initialize(admin_assignee: nil)
      @admin_assignee = admin_assignee.to_s.strip
    end

    def select_targeted(ticket:)
      return failure("ticket_not_found", "ticket was not found") unless ticket
      return failure("ticket_archived", "archived tickets are not eligible for agent execution") if ticket.archived_at.present?
      return failure("ticket_not_development_ready", "ticket is not in a development-capable state") unless development_ready?(ticket)
      success(ticket)
    end

    def pick(board:, project_id: nil, assignee: nil)
      project = board&.project || Project.find_by(id: project_id)
      Ticket.reconcile!(project) if project
      relation = base_relation(board: board, project_id: project_id)
      return failure("board_not_found", "board was not found") unless relation

      relation = relation.where(assignee: assignee.to_s.strip) if assignee.to_s.strip.present?
      ticket = project ? Specifications::Tracker.new(project: project).pick(relation) : relation.ordered_for_board.first
      return failure("ticket_not_found", "no eligible ticket was found") unless ticket

      success(ticket)
    end

    private

    attr_reader :admin_assignee

    def base_relation(board:, project_id:)
      scope = if board
                board.tickets
              elsif project_id.present?
                Ticket.for_project(project_id)
              end
      return nil unless scope

      relation = scope.visible_on_board
                      .joins(:column)
                      .where(columns: {key: DEVELOPMENT_COLUMN_KEYS})
                      .where(workflow_status: DEVELOPMENT_WORKFLOW_STATUSES)
      return relation if admin_assignee.blank?

      relation.where("tickets.assignee IS NULL OR tickets.assignee != ?", admin_assignee)
    end

    def development_ready?(ticket)
      DEVELOPMENT_COLUMN_KEYS.include?(ticket.column.key) &&
        DEVELOPMENT_WORKFLOW_STATUSES.include?(ticket.workflow_status)
    end

    def success(ticket)
      Result.new(ok: true, ticket: ticket)
    end

    def failure(code, message)
      Result.new(ok: false, ticket: nil, code: code, message: message)
    end
  end
end
