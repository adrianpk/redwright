require "test_helper"

class BoardsControllerTest < ActionDispatch::IntegrationTest
  test "index redirects to login without authentication" do
    Board.create!(name: "Factory", project_key: "factory")

    get boards_path
    assert_redirected_to new_session_path
  end

  test "index renders boards with authentication" do
    user = User.create!(
      email_address: "owner@example.test",
      password: "password-123",
      password_confirmation: "password-123",
      roles: [ "admin" ]
    )
    Board.create!(name: "Factory", project_key: "factory")

    sign_in_as(user)
    get boards_path
    assert_response :success
    assert_match "Factory", response.body
    assert_match "Document Canvas", response.body
    assert_match "href=\"#{document_artifacts_path}\"", response.body
  end

  test "board lifecycle shows elapsed metrics after review and merge transitions" do
    user = User.create!(
      email_address: "owner2@example.test",
      password: "password-123",
      password_confirmation: "password-123",
      roles: [ "admin" ]
    )
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

    sign_in_as(user)
    get board_path(board)
    assert_response :success
    assert_match("Implement parser", response.body)
    assert_match("drag-drop-zones", response.body)
    assert_match("data-drop-action=\"archive\"", response.body)
    assert_match("data-drop-action=\"delete\"", response.body)
    assert_match("column-grip is-hidden", response.body)
    assert_match("data-edit-url=", response.body)
  end
end
