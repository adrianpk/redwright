require "test_helper"

class SpecificationsTrackerTest < ActiveSupport::TestCase
  test "generated tracker orders real tickets and derives completion including reopen" do
    specification = create_document(status: "approved")
    board = create_board(project: specification.project)
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    done = board.columns.create!(key: "done", title: "Done", position: 1)
    first = board.tickets.create!(column: backlog, title: "First implementation")
    second = board.tickets.create!(column: backlog, title: "Second implementation")
    tracker = Specifications::Tracker.new(project: specification.project)
    entry = tracker.generate!(specification: specification, tickets: [second, first])
    assert_equal [second.ticket_key, first.ticket_key], entry[:metadata]["ticket_keys"]
    assert_equal [second.id, first.id], tracker.pending_tickets.map(&:id)
    assert_equal second.id, AgentTicketExecution::TicketSelectionPolicy.new.pick(board: board).ticket.id
    second.transition_to_column!(done)
    assert_equal [first.id], tracker.pending_tickets.map(&:id)
    assert_equal first.id, AgentTicketExecution::TicketSelectionPolicy.new.pick(board: board).ticket.id
    second.transition_to_column!(backlog)
    assert_equal [second.id, first.id], tracker.pending_tickets.map(&:id)
    assert_equal second.id, AgentTicketExecution::TicketSelectionPolicy.new.pick(board: board).ticket.id
    refute_match(/\[[ x]\]/, entry[:body])
  end
end
