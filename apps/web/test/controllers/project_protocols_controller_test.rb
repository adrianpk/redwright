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
    assert_match "href=\"#{project_protocols_path(project)}\"", response.body
    assert_match "AGENTS.md", response.body
    assert_match ".agents/ARCHITECTURE.md", response.body
    assert_match "Open dedicated view", response.body
    assert_operator response.body.index("AGENTS.md"), :<, response.body.index(".agents/ARCHITECTURE.md")
  end

  test "index renders missing canonical entries as empty cards with create actions" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "protocols-missing")
    create_project_protocol(
      project: project,
      documents: [
        {key: "agents_root", path: "AGENTS.md", title: "AGENTS", position: 0, body: "# Root"}
      ]
    )

    get project_protocols_path(project)

    assert_response :success
    assert_match "Missing", response.body
    assert_match ".agents/CONVENTIONS.md", response.body
    assert_match "Create", response.body
  end

  test "playbooks renders dedicated subview" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "protocols-playbooks")
    create_project_protocol(
      project: project,
      documents: [
        {key: "agents_root", path: "AGENTS.md", title: "AGENTS", position: 0, body: "# Root"},
        {key: "playbooks_index", path: ".agents/PLAYBOOKS.md", title: "Playbooks", position: 3, body: "# Playbooks"},
        {key: "playbook_slice_delivery", path: ".agents/playbooks/slice-delivery.md", title: "Slice Delivery", position: 4, body: "# Slice Delivery"}
      ]
    )

    get playbooks_project_protocols_path(project)

    assert_response :success
    assert_match "Playbooks", response.body
    assert_match ".agents/playbooks/slice-delivery.md", response.body
    refute_match "AGENTS.md", response.body
  end

  test "create builds missing canonical protocol entry and redirects to the combined protocol screen" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "protocols-create")

    post project_protocols_path(project), params: {key: "agents_root"}

    document = project.reload.protocol.documents.find_by!(key: "agents_root")
    assert_redirected_to project_protocol_path(project, document)
    assert_equal "AGENTS.md", document.path
  end

  test "show renders combined read edit protocol screen" do
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
    assert_match "textarea", response.body
    assert_match "Last saved", response.body
    assert_match "Delete Protocol", response.body
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
    assert_redirected_to project_protocol_path(project, document)

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

  test "autosave updates protocol over json and returns updated timestamp" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "protocols-autosave")
    protocol = create_project_protocol(
      project: project,
      documents: [{key: "agents_root", path: "AGENTS.md", title: "AGENTS", body: "# Root"}]
    )
    document = protocol.documents.first

    patch project_protocol_path(project, document, format: :json), params: {
      project_protocol_document: {
        title: "AGENTS Autosaved",
        body: "# Autosaved Root"
      }
    }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal "AGENTS Autosaved", payload.fetch("title")
    assert payload.fetch("updated_at").present?
    assert_equal "AGENTS Autosaved", document.reload.title
  end

  test "delete and recreate canonical protocol entry" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "protocols-delete")
    protocol = create_project_protocol(
      project: project,
      documents: [{key: "conventions", path: ".agents/CONVENTIONS.md", title: "Conventions", body: "# Rules"}]
    )
    document = protocol.documents.first

    delete project_protocol_path(project, document)

    assert_redirected_to project_protocols_path(project)
    assert_nil protocol.reload.documents.find_by(id: document.id)

    post project_protocols_path(project), params: {key: "conventions"}

    recreated = project.reload.protocol.documents.find_by!(key: "conventions")
    assert_redirected_to project_protocol_path(project, recreated)
  end

  test "create does not duplicate an existing canonical protocol entry" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "protocols-no-duplicate")
    create_project_protocol(
      project: project,
      documents: [{key: "agents_root", path: "AGENTS.md", title: "AGENTS", body: "# Root"}]
    )

    assert_no_difference -> { project.reload.protocol.documents.where(key: "agents_root").count } do
      post project_protocols_path(project), params: {key: "agents_root"}
    end
  end
end
