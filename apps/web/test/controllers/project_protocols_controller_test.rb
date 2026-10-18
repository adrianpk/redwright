require "test_helper"

class ProjectProtocolsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email_address: "protocols-owner@example.com", password: "password-123", password_confirmation: "password-123")
    @project = create_project(key: "protocols-web")
    @store = write_protocol_files(project: @project, documents: [
      {path: "AGENTS.md", body: "# Root"},
      {path: ".agents/CONVENTIONS.md", body: "# Conventions"}
    ])
  end

  test "requires authentication" do
    get project_protocols_path(@project)
    assert_redirected_to new_session_path
  end

  # The index must reflect additions and removals without a canonical slot list.
  test "lists the actual project files" do
    sign_in_as(@admin)
    @store.create(".agents/custom/NOTES.md", "# Custom notes")
    @store.root.join(".agents/CONVENTIONS.md").delete
    get project_protocols_path(@project)
    assert_response :success
    assert_match "Custom / Notes", response.body
    assert_select ".board-key code", text: @store.root.to_s
    refute_match ">Conventions<", response.body
    refute @store.root.join(".agents/CONVENTIONS.md").exist?
  end

  # A shared file identifier must resolve within the requested project only.
  test "isolates project files from templates and other projects" do
    sign_in_as(@admin)
    other_project = create_project(key: "other-protocols-web")
    other_store = write_protocol_files(project: other_project, documents: [
      {path: "AGENTS.md", body: "# Other project instructions"},
      {path: ".agents/stacks/odin/CONVENTIONS.md", body: "# Other project Odin"}
    ])
    template = ProjectProtocols::TemplateCatalog.new.common_template.documents.find_by!(key: "agents_root")
    template.update!(body: "# Template instructions")

    get project_protocols_path(@project)
    assert_response :success
    assert_select ".artifact-type-card h2", text: /Odin/, count: 0

    document = @store.find_path("AGENTS.md")
    get project_protocol_path(@project, document)
    assert_response :success
    assert_select "textarea", text: "# Root"

    patch project_protocol_path(@project, document, format: :json), params: {
      protocol_document: {body: "# Updated project instructions", revision: document.revision}
    }
    assert_response :success
    assert_equal "# Updated project instructions", @store.root.join("AGENTS.md").read
    assert_equal "# Other project instructions", other_store.root.join("AGENTS.md").read
    assert_equal "# Template instructions", template.reload.body
    assert_equal ["AGENTS.md", ".agents/CONVENTIONS.md"], @store.documents.map(&:path)
  end

  # Missing project files must not be supplied by the global template catalog.
  test "keeps missing workspaces empty" do
    sign_in_as(@admin)
    ProjectProtocols::TemplateCatalog.new.common_template
    FileUtils.remove_entry(@store.root)

    get project_protocols_path(@project)

    assert_response :success
    assert_select ".board-key code", text: @store.root.to_s
    assert_select ".artifact-type-card", count: 0
    assert_match "No protocol files found", response.body
    refute @store.root.exist?
  end

  test "shows the current file in the editor" do
    sign_in_as(@admin)
    @store.root.join("AGENTS.md").write("# Changed externally")
    document = @store.find_path("AGENTS.md")
    get project_protocol_path(@project, document)
    assert_response :success
    assert_select "textarea", text: /Changed externally/
    assert_select ".board-key code", text: @store.root.join("AGENTS.md").to_s
    assert_select "input[name='protocol_document[revision]'][value=?]", document.revision
  end

  # JSON autosave writes the file and returns the next revision for the editor.
  test "autosaves to the selected file" do
    sign_in_as(@admin)
    document = @store.find_path("AGENTS.md")
    patch project_protocol_path(@project, document, format: :json), params: {
      protocol_document: {body: "# Saved from web", revision: document.revision}
    }
    assert_response :success
    assert_equal "# Saved from web", @store.root.join("AGENTS.md").read
    payload = response.parsed_body
    assert_equal @store.find_path("AGENTS.md").revision, payload.fetch("revision")
    assert payload.fetch("updated_at").present?
    assert_equal "# Conventions", @store.root.join(".agents/CONVENTIONS.md").read
  end

  test "rejects an outdated browser edit" do
    sign_in_as(@admin)
    document = @store.find_path("AGENTS.md")
    @store.root.join("AGENTS.md").write("# Newer external edit")
    patch project_protocol_path(@project, document, format: :json), params: {
      protocol_document: {body: "# Outdated", revision: document.revision}
    }
    assert_response :conflict
    assert_equal "# Newer external edit", @store.root.join("AGENTS.md").read
  end

  test "does not recreate deleted files" do
    sign_in_as(@admin)
    document = @store.find_path("AGENTS.md")
    @store.root.join("AGENTS.md").delete
    get project_protocol_path(@project, document)
    assert_response :not_found
    get project_protocols_path(@project)
    assert_response :success
    refute @store.root.join("AGENTS.md").exist?
  end

  test "keeps playbooks reachable without an index file" do
    sign_in_as(@admin)
    document = @store.create(".agents/playbooks/custom.md", "# Custom playbook")
    get project_protocols_path(@project)
    assert_response :success
    assert_match project_protocol_path(@project, document), response.body
    get playbooks_project_protocols_path(@project)
    assert_response :success
    assert_match "Custom playbook", response.body
  end
end
