require "test_helper"

class UseCasesControllerTest < ActionDispatch::IntegrationTest
  def create_admin_user!
    User.create!(
      email_address: "use-cases-owner@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
  end

  test "index requires authentication" do
    project = create_project(key: "use-cases-auth")

    get project_use_cases_path(project)

    assert_redirected_to new_session_path
  end

  test "index renders current project use cases newest first" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(name: "Visible Use Case Project", key: "use-cases-visible")
    other_project = create_project(name: "Hidden Use Case Project", key: "use-cases-hidden")
    older = create_use_case(project: project, name: "Billing", description: "Invoice behavior.")
    newer = create_use_case(project: project, name: "Checkout", description: "Checkout behavior.")
    create_use_case(project: other_project, name: "Hidden", description: "Hidden behavior.")
    older.update_column(:created_at, 2.days.ago)
    newer.update_column(:created_at, 1.day.ago)

    get project_use_cases_path(project)

    assert_response :success
    assert_match "Use Cases", response.body
    assert_match "Billing", response.body
    assert_match "Invoice behavior.", response.body
    assert_match "Checkout", response.body
    assert_match "checkout", response.body
    assert_operator response.body.index("Checkout"), :<, response.body.index("Billing")
    refute_match "Hidden behavior.", response.body
  end

  test "index exposes edit action without delete or association counters" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "use-cases-actions")
    use_case = create_use_case(project: project, name: "Billing")

    get project_use_cases_path(project)

    assert_response :success
    assert_match "Edit", response.body
    assert_match "##{use_case.slug}", response.body
    refute_match "Delete", response.body
    refute_match "Tickets", response.body
    refute_match "Documents", response.body
  end

  test "top navigation places use cases between protocols and quizzes" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "use-cases-nav")

    get project_use_cases_path(project)

    assert_response :success
    assert_operator response.body.index("Protocols"), :<, response.body.index("Use Cases")
    assert_operator response.body.index("Use Cases"), :<, response.body.index("Quizzes")
    assert_match "href=\"#{project_use_cases_path(project)}\"", response.body
  end
end
