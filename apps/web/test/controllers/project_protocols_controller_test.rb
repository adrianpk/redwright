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
    assert_match "Playbooks", response.body
    assert_operator response.body.index("AGENTS"), :<, response.body.index("Architecture")
    refute_match ".agents/ARCHITECTURE.md", response.body
  end

  test "index materializes missing canonical entries as stable editable slots" do
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
    assert_match "Conventions", response.body
    refute_match ".agents/CONVENTIONS.md", response.body
    refute_match "Create", response.body
    assert project.reload.protocol.documents.find_by(key: "conventions")
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
    assert_match "Slice Delivery", response.body
    refute_match ".agents/playbooks/slice-delivery.md", response.body
    refute_match "AGENTS.md", response.body
  end

  test "materialized canonical protocol entry renders template body as placeholder only" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "protocols-placeholder")

    get project_protocols_path(project)
    document = project.reload.protocol.documents.find_by!(key: "conventions")


    get project_protocol_path(project, document)

    assert_response :success
    assert_equal "", document.body
    assert_match "placeholder=", response.body
    assert_match "<textarea", response.body
    refute_match "># Conventions", response.body
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
    refute_match "Delete Protocol", response.body
    refute_match "AGENTS.md", response.body
    refute_match "Project protocol", response.body
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

  test "index reconstitutes deleted canonical protocol entry as empty slot" do
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

    get project_protocols_path(project)

    recreated = project.reload.protocol.documents.find_by!(key: "conventions")
    assert_equal "", recreated.body
  end

  test "index does not duplicate existing canonical protocol entry" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "protocols-no-duplicate")
    create_project_protocol(
      project: project,
      documents: [{key: "agents_root", path: "AGENTS.md", title: "AGENTS", body: "# Root"}]
    )

    assert_no_difference -> { project.reload.protocol.documents.where(key: "agents_root").count } do
      get project_protocols_path(project)
    end
  end
end
