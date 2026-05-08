module AgentTicketExecution
  class KanbanTransitioner
    START_COLUMN_KEY = "in_progress".freeze
    REVIEW_COLUMN_KEY = "review".freeze
    BLOCKED_COLUMN_KEY = "blocked".freeze

    Result = Struct.new(:status, :from_column_key, :to_column_key, :reason, keyword_init: true) do
      def moved?
        status == "moved"
      end

      def to_h
        {
          "status" => status,
          "from_column_key" => from_column_key,
          "to_column_key" => to_column_key,
          "reason" => reason
        }.compact
      end
    end

    def mark_started(ticket:)
      transition(ticket: ticket, target_column_key: START_COLUMN_KEY)
    end

    def apply_terminal_outcome(ticket:, execution:)
      terminal_outcome = execution.fetch("terminal_outcome", {}) || {}
      status = terminal_outcome.fetch("status", execution.fetch("state", nil)).to_s

      return transition(ticket: ticket, target_column_key: REVIEW_COLUMN_KEY) if status == "ready_for_review"
      return transition(ticket: ticket, target_column_key: BLOCKED_COLUMN_KEY) if status == "blocked"

      skipped(ticket: ticket, reason: "terminal_outcome_not_transitionable")
    end

    private

    def transition(ticket:, target_column_key:)
      from_column_key = ticket.column.key
      return skipped(ticket: ticket, reason: "already_in_target_column", target_column_key: target_column_key) if from_column_key == target_column_key

      target_column = ticket.board.columns.find_by(key: target_column_key)
      return skipped(ticket: ticket, reason: "target_column_missing", target_column_key: target_column_key) unless target_column

      ticket.transition_to_column!(target_column)
      Result.new(
        status: "moved",
        from_column_key: from_column_key,
        to_column_key: target_column_key
      )
    end

    def skipped(ticket:, reason:, target_column_key: nil)
      Result.new(
        status: "skipped",
        from_column_key: ticket.column.key,
        to_column_key: target_column_key,
        reason: reason
      )
    end
  end
end
