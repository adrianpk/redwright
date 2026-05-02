require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  def create_admin_user!
    User.create!(
      email_address: "projects-owner@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
  end

  test "new renders project initialization form" do
    admin = create_admin_user!
    sign_in_as(admin)

    get new_project_path

    assert_response :success
    assert_match "New Project", response.body
    assert_match "Repository", response.body
  end

  test "create initializes project from repository-first flow with guided alignment opt-in" do
    admin = create_admin_user!
    sign_in_as(admin)

    post projects_path, params: {
      project: {
        name: "Inventory Service",
        directory_name: "inventory-service",
        repository_input: "acme/inventory-service",
        guided_alignment: true
      }
    }

    project = Project.order(:created_at).last
    assert_redirected_to project_path(project)
    follow_redirect!
    assert_match "Inventory Service", response.body
    assert_equal "/workspace/projects/inventory-service", project.root_path
    assert_equal "https://github.com/acme/inventory-service.git", project.repo_url
    session = project.project_setup_sessions.order(:created_at).last
    assert_equal "open", session.status
    assert_equal "collecting_alignment", session.current_state
    assert_equal "Guided alignment is ready to continue.", session.pending_question
  end

  test "create supports guided alignment opt-out" do
    admin = create_admin_user!
    sign_in_as(admin)

    post projects_path, params: {
      project: {
        name: "Billing Service",
        directory_name: "billing-service",
        repository_input: "acme/billing-service",
        guided_alignment: false
      }
    }

    project = Project.order(:created_at).last
    assert_redirected_to project_path(project)
    follow_redirect!
    assert_match "Billing Service", response.body
    session = project.project_setup_sessions.order(:created_at).last
    assert_equal "completed", session.status
    assert_equal "completed", session.current_state
    assert_equal "completed_without_alignment", session.terminal_reason
  end

  test "create rejects ambiguous repository input" do
    admin = create_admin_user!
    sign_in_as(admin)

    post projects_path, params: {
      project: {
        name: "Inventory Service",
        directory_name: "inventory-service",
        repository_input: "inventory-service",
        guided_alignment: true
      }
    }

    assert_response :unprocessable_entity
    assert_match "requires clarification", response.body
    session = ProjectSetupSession.order(:created_at).last
    assert_equal "awaiting_repository", session.current_state
    assert_nil session.project
  end
end
