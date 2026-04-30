require "test_helper"

class BoardsControllerTest < ActionDispatch::IntegrationTest
  test "index renders boards" do
    Board.create!(name: "Factory", project_key: "factory")

    get boards_path
    assert_response :success
    assert_match "Factory", response.body
  end

  test "board lifecycle shows elapsed metrics after review and merge transitions" do
    board = Board.create!(name: "Factory", project_key: "factory")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    review = board.columns.create!(key: "review", title: "Review", position: 1)
    approved = board.columns.create!(key: "approved", title: "Approved", position: 2)
    merged = board.columns.create!(key: "merged", title: "Merged", position: 3)
    ticket = board.tickets.create!(column: backlog, title: "Implement parser", priority: :high)

    ticket.update!(started_at: Time.current - 120)
    ticket.transition_to_column!(review)
    ticket.transition_to_column!(approved)
    ticket.transition_to_column!(merged)

    get board_path(board)
    assert_response :success
    assert_match("Total elapsed:", response.body)
    assert_match("Review elapsed:", response.body)
    assert_match("Implement parser", response.body)
  end
end
