require "test_helper"

class DocumentCanvasNavigationFlowTest < ActionDispatch::IntegrationTest
  def create_admin_user!
    User.create!(
      email_address: "nav-admin@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
  end

  test "board and document canvas are mutually reachable from top navigation" do
    admin = create_admin_user!
    board = create_board(project_key: "factory-nav")
    sign_in_as(admin)

    get boards_path
    assert_redirected_to board_path(board)

    follow_redirect!
    assert_response :success
    assert_match "Specs", response.body
    assert_match "href=\"#{documents_path(project_id: board.project_id)}\"", response.body

    write_protocol_files(project: board.project)
    get documents_path
    assert_response :success
    assert_match "Board", response.body
    assert_match "href=\"#{board_path(board)}\"", response.body
    assert_match "artifact-type-nav", response.body
  end
end
