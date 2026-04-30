require "test_helper"

class TicketsControllerTest < ActionDispatch::IntegrationTest
  test "create persists ticket from board form" do
    board = Board.create!(name: "Factory", project_key: "factory-create")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)

    post board_tickets_path(board), params: {
      ticket: {
        title: "Create endpoint",
        description: "Need a new endpoint",
        priority: "high",
        assignee: "agent-1",
        column_id: backlog.id
      }
    }

    assert_redirected_to board_path(board)
    created = board.tickets.order(:created_at).last
    assert_equal "Create endpoint", created.title
    assert_equal "high", created.priority
  end

  test "update edits existing ticket" do
    board = Board.create!(name: "Factory", project_key: "factory-update")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Old title")

    patch ticket_path(ticket), params: {
      ticket: { title: "New title", priority: "low" }
    }

    assert_redirected_to board_path(board)
    assert_equal "New title", ticket.reload.title
    assert_equal "low", ticket.priority
  end

  test "move updates ticket column and returns turbo stream" do
    board = Board.create!(name: "Factory", project_key: "factory")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    review = board.columns.create!(key: "review", title: "Review", position: 1)
    ticket = board.tickets.create!(column: backlog, title: "Create model")

    patch move_ticket_path(ticket, format: :turbo_stream),
      params: { column_id: review.id }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.media_type + "; charset=utf-8"
    assert_equal review.id, ticket.reload.column_id
  end

  test "pick returns assignee-prioritized ticket" do
    board = Board.create!(name: "Factory", project_key: "factory")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    board.tickets.create!(column: backlog, title: "General high", priority: :high)
    selected = board.tickets.create!(column: backlog, title: "Mine medium", priority: :medium, assignee: "agent-1")

    get pick_board_tickets_path(board), params: { assignee: "agent-1" }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal selected.id, json.fetch("id")
  end

  test "archive removes ticket from board scope" do
    board = Board.create!(name: "Factory", project_key: "factory-archive")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Archive me")

    patch archive_ticket_path(ticket, format: :turbo_stream)

    assert_response :success
    assert_not_nil ticket.reload.archived_at
    assert_equal 0, board.tickets.visible_on_board.count
  end

  test "destroy removes ticket from database" do
    board = Board.create!(name: "Factory", project_key: "factory-delete")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Delete me")

    delete ticket_path(ticket, format: :turbo_stream)

    assert_response :success
    assert_nil Ticket.find_by(id: ticket.id)
  end
end
