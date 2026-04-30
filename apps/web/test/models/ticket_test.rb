require "test_helper"

class TicketTest < ActiveSupport::TestCase
  test "transition_to_column stamps review and merge phase times" do
    board = Board.create!(name: "Factory", project_key: "factory")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    review = board.columns.create!(key: "review", title: "Review", position: 1)
    merged = board.columns.create!(key: "merged", title: "Merged", position: 2)
    ticket = board.tickets.create!(column: backlog, title: "Implement parser", priority: :high)

    ticket.transition_to_column!(review)
    assert_not_nil ticket.sent_to_review_at
    assert_not_nil ticket.review_started_at

    ticket.transition_to_column!(merged)
    assert_not_nil ticket.merge_started_at
    assert_not_nil ticket.merged_at
  end

  test "pick_next_for prefers assignee and falls back to highest priority" do
    board = Board.create!(name: "Factory", project_key: "factory")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    board.columns.create!(key: "merged", title: "Merged", position: 1)

    board.tickets.create!(column: backlog, title: "General low", priority: :low)
    high = board.tickets.create!(column: backlog, title: "General high", priority: :high)
    assigned = board.tickets.create!(column: backlog, title: "Mine medium", priority: :medium, assignee: "agent-1")

    assert_equal assigned.id, Ticket.pick_next_for(board: board, assignee: "agent-1").id
    assert_equal high.id, Ticket.pick_next_for(board: board, assignee: "agent-2").id
  end
end
