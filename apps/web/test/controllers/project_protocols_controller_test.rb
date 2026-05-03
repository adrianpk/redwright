require "test_helper"

class ProjectProtocolsControllerTest < ActionDispatch::IntegrationTest
  def create_admin_user!
    User.create!(
      email_address: "protocols-owner@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
  end

  test "index requires authentication" do
    project = create_project(key: "protocols-auth")

    get project_protocols_path(project)

    assert_redirected_to new_session_path
  end

  test "index renders project protocol documents in canonical order" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "protocols-index")
    create_project_protocol(
      project: project,
      documents: [
        {key: "agents_root", path: "AGENTS.md", title: "AGENTS", position: 0, body: "# Root"},
        {key: "architecture", path: ".agents/ARCHITECTURE.md", title: "Architecture", position: 1, body: "# Architecture"},
        {key: "playbooks_index", path: ".agents/PLAYBOOKS.md", title: "Playbooks", position: 2, body: "# Playbooks"}
      ]
    )

    get project_protocols_path(project)

    assert_response :success
    assert_match "Protocols", response.body
    assert_match "AGENTS.md", response.body
    assert_match ".agents/ARCHITECTURE.md", response.body
    assert_match ".agents/PLAYBOOKS.md", response.body
    assert_operator response.body.index("AGENTS.md"), :<, response.body.index(".agents/ARCHITECTURE.md")
  end

  test "show renders one protocol document" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "protocols-show")
    protocol = create_project_protocol(
      project: project,
      documents: [{key: "agents_root", path: "AGENTS.md", title: "AGENTS", body: "# Root\n\nRead first."}]
    )

    get project_protocol_path(project, protocol.documents.first)

    assert_response :success
    assert_match "AGENTS", response.body
    assert_match "Read first.", response.body
    assert_match "Edit Protocol", response.body
  end

  test "edit and update protocol markdown" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "protocols-edit")
    protocol = create_project_protocol(
      project: project,
      documents: [{key: "agents_root", path: "AGENTS.md", title: "AGENTS", body: "# Root"}]
    )
    document = protocol.documents.first

    get edit_project_protocol_path(project, document)
    assert_response :success
    assert_match "Edit Protocol", response.body

    patch project_protocol_path(project, document), params: {
      project_protocol_document: {
        title: "AGENTS Updated",
        body: "# Updated Root"
      }
    }

    assert_redirected_to project_protocol_path(project, document)
    assert_equal "AGENTS Updated", document.reload.title
    assert_equal "# Updated Root", document.reload.body
  end
end
