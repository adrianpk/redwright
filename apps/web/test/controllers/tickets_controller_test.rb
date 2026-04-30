require "test_helper"

class TicketsControllerTest < ActionDispatch::IntegrationTest
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
end
