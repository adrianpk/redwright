require "test_helper"

module AgentTicketExecution
  class TicketSelectionPolicyTest < ActiveSupport::TestCase
    test "selects a targeted development-ready ticket" do
      board = create_board(project_key: "ticket-selection-targeted-#{SecureRandom.hex(4)}")
      backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      ticket = board.tickets.create!(column: backlog, title: "Implement target")

      result = TicketSelectionPolicy.new.select_targeted(ticket: ticket)

      assert result.ok?
      assert_equal ticket, result.ticket
    end

    test "rejects targeted tickets outside development-capable states" do
      board = create_board(project_key: "ticket-selection-review-#{SecureRandom.hex(4)}")
      review = board.columns.create!(key: "review", title: "Review", position: 0)
      ticket = board.tickets.create!(column: review, title: "Reviewing target")

      result = TicketSelectionPolicy.new.select_targeted(ticket: ticket)

      assert_not result.ok?
      assert_equal "ticket_not_development_ready", result.code
    end

    test "pickup skips admin self-assigned tickets and selects the next eligible ticket" do
      board = create_board(project_key: "ticket-selection-pickup-#{SecureRandom.hex(4)}")
      backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      admin_ticket = board.tickets.create!(column: backlog, title: "Admin task", assignee: "admin")
      agent_ticket = board.tickets.create!(column: backlog, title: "Agent task", assignee: "agent-coder")
      admin_ticket.update!(priority: :high)
      agent_ticket.update!(priority: :medium)

      result = TicketSelectionPolicy.new(admin_assignee: "admin").pick(board: board)

      assert result.ok?
      assert_equal agent_ticket, result.ticket
    end

    test "pickup excludes blocked and review tickets" do
      board = create_board(project_key: "ticket-selection-blocked-#{SecureRandom.hex(4)}")
      blocked = board.columns.create!(key: "blocked", title: "Blocked", position: 0)
      review = board.columns.create!(key: "review", title: "Review", position: 1)
      board.tickets.create!(column: blocked, title: "Blocked task")
      board.tickets.create!(column: review, title: "Review task")

      result = TicketSelectionPolicy.new.pick(board: board)

      assert_not result.ok?
      assert_equal "ticket_not_found", result.code
    end
  end
end
