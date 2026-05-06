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
    assert_match edit_project_use_case_path(project, use_case), response.body
    refute_match "Delete", response.body
    refute_match "Tickets", response.body
    refute_match "Documents", response.body
  end

  test "new renders modal form without slug input" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "use-cases-new")

    get new_project_use_case_path(project)

    assert_response :success
    assert_match "New Use Case", response.body
    assert_match "Name", response.body
    assert_match "Description", response.body
    refute_match "name=\"use_case[slug]\"", response.body
  end

  test "creates use case and redirects to project index" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "use-cases-create")

    post project_use_cases_path(project), params: {
      use_case: {
        name: "Billing Flow",
        description: "Invoice and payment behavior."
      }
    }

    use_case = project.use_cases.find_by!(slug: "billing-flow")
    assert_redirected_to project_use_cases_path(project)
    assert_equal "Invoice and payment behavior.", use_case.description
  end

  test "create renders validation errors" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "use-cases-create-invalid")

    post project_use_cases_path(project), params: {
      use_case: {
        name: "",
        description: ""
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Name can&#39;t be blank"
    assert_includes response.body, "Description can&#39;t be blank"
    refute_includes response.body, "Slug can&#39;t be blank"
  end

  test "edit uses slug path and does not expose slug input" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "use-cases-edit")
    use_case = create_use_case(project: project, name: "Billing")

    get edit_project_use_case_path(project, use_case)

    assert_response :success
    assert_match "Edit Use Case", response.body
    assert_match "Billing", response.body
    refute_match "name=\"use_case[slug]\"", response.body
  end

  test "updates use case and keeps slug generated from name" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "use-cases-update")
    use_case = create_use_case(project: project, name: "Billing")

    patch project_use_case_path(project, use_case), params: {
      use_case: {
        name: "Invoice Flow",
        description: "Invoice lifecycle behavior."
      }
    }

    assert_redirected_to project_use_cases_path(project)
    use_case.reload
    assert_equal "Invoice Flow", use_case.name
    assert_equal "invoice-flow", use_case.slug
    assert_equal "Invoice lifecycle behavior.", use_case.description
  end

  test "update renders validation errors" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "use-cases-update-invalid")
    use_case = create_use_case(project: project, name: "Billing")

    patch project_use_case_path(project, use_case), params: {
      use_case: {
        name: "",
        description: ""
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Name can&#39;t be blank"
    assert_includes response.body, "Description can&#39;t be blank"
    refute_includes response.body, "Slug can&#39;t be blank"
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
