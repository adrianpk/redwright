require "test_helper"

class ProjectConversationsControllerTest < ActionDispatch::IntegrationTest
  def create_admin_user!
    User.create!(
      email_address: "conversation-owner@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
  end

  test "show requires authentication" do
    project = create_project(key: "conversation-controller-auth")

    get project_conversation_path(project)

    assert_redirected_to new_session_path
  end

  test "show renders conversation modes as sibling cards" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(name: "Conversation Project", key: "conversation-controller-show")
    project.find_or_create_main_quiz!
    project.dumps.create!(title: "Context dump")

    get project_conversation_path(project)

    assert_response :success
    assert_select "h1", text: "Conversation"
    assert_match "Project: Conversation Project", response.body
    assert_select ".artifact-type-card h2", text: "Dump"
    assert_select ".artifact-type-card h2", text: "Quizzes"
    assert_select "a.artifact-type-card[href='#{project_quizzes_path(project)}'] h2", text: "Quizzes"
    assert_match "1 dump", response.body
    assert_match "1 quiz", response.body
  end

  test "top navigation points to conversation instead of quizzes" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "conversation-controller-nav")

    get project_conversation_path(project)

    assert_response :success
    assert_select ".top-nav-link[href='#{project_conversation_path(project)}']", text: "Conv"
    assert_select ".top-nav-link[href='#{project_quizzes_path(project)}']", count: 0
  end
end
