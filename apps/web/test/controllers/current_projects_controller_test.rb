require "test_helper"

class CurrentProjectsControllerTest < ActionDispatch::IntegrationTest
  test "update persists selected project in session and redirects to selected project board" do
    user = User.create!(
      email_address: "selector@example.test",
      password: "password-123",
      password_confirmation: "password-123"
    )
    project = create_project(key: "selector-project")
    board = create_board(project_key: "selector-project", project: project)

    sign_in_as(user)
    patch current_project_path, params: { project_id: project.id }, headers: { "Referer" => documents_path }

    assert_redirected_to board_path(board)

    get boards_path
    assert_redirected_to board_path(board)
  end
end
