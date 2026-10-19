require "test_helper"
require_relative "../support/protocol_reference_harness_fixture"

class ProjectProtocolsControllerTest < ActionDispatch::IntegrationTest
  include ProtocolReferenceHarnessFixture
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
    post sync_references_project_protocol_path(@project, @store.find_path("AGENTS.md")), as: :json
    assert_redirected_to new_session_path
  end

  test "syncs references only from the AGENTS editor" do
    # Use real project files and the subprocess fixture without depending on model availability.
    sign_in_as(@admin)
    previous = ENV["REDWRIGHT_PROTOCOL_HARNESS"]
    ENV["REDWRIGHT_PROTOCOL_HARNESS"] = protocol_reference_harness(@store.root)
    @store.create(".agents/nested/NOTES.md", "# Nested collaboration notes")
    agents = @store.find_path("AGENTS.md")
    get project_protocol_path(@project, agents)
    assert_select "button[data-protocol-sync]", text: "Sync"
    pending = agents.body + "\n\nKeep this pending edit.\n"

    post sync_references_project_protocol_path(@project, agents), params: {
      protocol_document: {body: pending, revision: agents.revision}
    }, as: :json

    assert_response :success
    payload = response.parsed_body
    assert payload.fetch("body").start_with?(pending)
    assert_includes payload.fetch("body"), "`.agents/nested/NOTES.md`"
    assert_includes payload.fetch("body"), "`.agents/CONVENTIONS.md`"
    assert_equal @store.find_path("AGENTS.md").revision, payload.fetch("revision")
    assert_equal payload.fetch("revision"), payload.fetch("agents_revision")
    document = @store.find_path(".agents/CONVENTIONS.md")
    get project_protocol_path(@project, document)
    assert_select "button[data-protocol-sync]", count: 0
    post sync_references_project_protocol_path(@project, document), params: {
      protocol_document: {revision: document.revision}
    }, as: :json
    assert_response :unprocessable_entity
    assert_equal "# Conventions", @store.snapshot(document.path).fetch(:body)
    post sync_references_project_protocol_path(@project, agents), params: {
      protocol_document: {revision: agents.revision}
    }, as: :json
    assert_response :conflict
    assert_equal payload.fetch("body"), @store.snapshot("AGENTS.md").fetch(:body)
  ensure
    ENV["REDWRIGHT_PROTOCOL_HARNESS"] = previous
  end

  test "creates renames and deletes a concern through the web" do
    # The model response is fixed; Rails still invokes the subprocess and writes real files.
    sign_in_as(@admin)
    previous = ENV["REDWRIGHT_PROTOCOL_HARNESS"]
    ENV["REDWRIGHT_PROTOCOL_HARNESS"] = protocol_reference_harness(@store.root)
    get project_protocols_path(@project)
    assert_select "a", text: "New"
    get new_project_protocol_path(@project)
    assert_response :success
    assert_select "input[name='protocol_document[name]']"
    assert_select "input[name='protocol_document[description]']"
    assert_select "textarea[name='protocol_document[body]']"

    post project_protocols_path(@project), params: {protocol_document: {
      name: "invariants", description: "Non-negotiable collaboration rules.", body: "# Scope\n\nStay within approved scope."
    }}
    document = @store.find_path(".agents/INVARIANTS.md")
    assert_redirected_to project_protocol_path(@project, document)
    follow_redirect!
    assert_select "input[name='protocol_document[description]'][value=?]", "Non-negotiable collaboration rules."
    assert_select "button", text: "Delete"
    assert_select "main .board-key", count: 0
    assert_includes @store.root.join("AGENTS.md").read, "`.agents/INVARIANTS.md` — Non-negotiable collaboration rules."
    get project_protocols_path(@project)
    assert_select ".artifact-type-card h2:first", text: "AGENTS"
    assert_select ".artifact-type-card h2", text: "Invariants"

    patch project_protocol_path(@project, document), params: {protocol_document: {
      name: "boundaries", description: "Scope boundaries.", body: "Updated Markdown", revision: document.revision,
      agents_revision: document.agents_revision
    }}
    renamed = @store.find_path(".agents/BOUNDARIES.md")
    assert_redirected_to project_protocol_path(@project, renamed)
    refute @store.root.join(".agents/INVARIANTS.md").exist?
    assert_equal "Updated Markdown", renamed.body
    assert_no_match ".agents/INVARIANTS.md", @store.root.join("AGENTS.md").read

    delete project_protocol_path(@project, renamed), params: {protocol_document: {revision: renamed.revision, agents_revision: renamed.agents_revision}}
    assert_redirected_to project_protocols_path(@project)
    refute @store.root.join(renamed.path).exist?
    assert_no_match renamed.path, @store.root.join("AGENTS.md").read
  ensure
    ENV["REDWRIGHT_PROTOCOL_HARNESS"] = previous
  end

  test "invalid creation retains entered fields and missing entrypoints are created on success" do
    sign_in_as(@admin)
    post project_protocols_path(@project), params: {protocol_document: {name: "../bad", description: "Useful context.", body: "Unsaved Markdown"}}
    assert_response :unprocessable_entity
    assert_select "input[name='protocol_document[name]'][value='../bad']"
    assert_select "textarea", text: "Unsaved Markdown"
    @store.root.join("AGENTS.md").delete
    previous = ENV["REDWRIGHT_PROTOCOL_HARNESS"]
    ENV["REDWRIGHT_PROTOCOL_HARNESS"] = protocol_reference_harness(@store.root)
    post project_protocols_path(@project), params: {protocol_document: {name: "custom", body: "Custom rules"}}
    assert_response :redirect
    assert_equal "AGENTS.md", @store.documents.first.path
    assert_includes @store.root.join("AGENTS.md").read, ".agents/CUSTOM.md"
  ensure
    ENV["REDWRIGHT_PROTOCOL_HARNESS"] = previous
  end

  # The index must reflect additions and removals without a canonical slot list.
  test "lists the actual project files" do
    sign_in_as(@admin)
    @store.create(".agents/custom/NOTES.md", "# Custom notes")
    @store.root.join(".agents/CONVENTIONS.md").delete
    get project_protocols_path(@project)
    assert_response :success
    assert_match "Custom / Notes", response.body
    assert_no_match @store.root.to_s, response.body
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
    assert_no_match @store.root.to_s, response.body
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
    assert_no_match @store.root.to_s, response.body
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
    assert_no_match @store.root.to_s, response.body
  end
end
