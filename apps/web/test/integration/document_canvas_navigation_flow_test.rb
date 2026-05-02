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
    create_board(project_key: "factory-nav")
    sign_in_as(admin)

    get boards_path
    assert_response :success
    assert_match "Docs", response.body
    assert_match "href=\"#{document_artifacts_path}\"", response.body

    get document_artifacts_path
    assert_response :success
    assert_match "Board", response.body
    assert_match "href=\"#{boards_path}\"", response.body
    assert_match "artifact-type-nav", response.body
  end
end
