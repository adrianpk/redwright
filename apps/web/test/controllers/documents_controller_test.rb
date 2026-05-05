require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  def create_admin_user!
    User.create!(
      email_address: "docs-owner@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
  end

  test "index requires authentication" do
    get documents_path
    assert_redirected_to new_session_path
  end

  test "create and update draft" do
    admin = create_admin_user!
    sign_in_as(admin)

    post documents_path, params: {
      document: {
        title: "Feature Draft",
        body: "Initial draft body"
      }
    }
    created = Document.order(:created_at).last
    assert_redirected_to document_path(created)
    assert_equal "draft", created.artifact_type
    assert_equal true, created.editable

    patch document_path(created), params: {
      document: {
        title: "Feature Draft Updated",
        body: "Updated body"
      }
    }
    assert_redirected_to document_path(created)
    assert_equal "Feature Draft Updated", created.reload.title
  end

  test "index renders top navigation back to board" do
    admin = create_admin_user!
    board = create_board(project_key: "docs-nav")
    sign_in_as(admin)

    patch current_project_path, params: { project_id: board.project_id }
    get documents_path
    assert_response :success
    assert_match "Board", response.body
    assert_match "href=\"#{board_path(board)}\"", response.body
  end

  test "promote draft to spec with lineage and relation" do
    admin = create_admin_user!
    sign_in_as(admin)
    draft = create_document(
      artifact_type: "draft",
      title: "Draft for Promotion",
      body: "Draft content"
    )

    post promote_document_path(draft)

    promoted = Document.order(:created_at).last
    assert_equal "spec", promoted.artifact_type
    assert_equal draft.id, promoted.source_draft_id
    assert_equal false, promoted.editable
    relation = DocumentRelation.find_by(from_artifact_id: promoted.id, to_artifact_id: draft.id)
    refute_nil relation
    assert_equal "derives_from", relation.relation_type
  end

  test "index filters by artifact type for spec and plan tracker" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "docs-type-filter")
    draft = create_document(project: project, artifact_type: "draft", title: "Draft One", body: "draft")
    create_document(project: project, artifact_type: "spec", title: "Spec One", body: "spec", source_draft: draft, editable: false)
    create_document(project: project, artifact_type: "plan_tracker", title: "Plan One", body: "plan", editable: false)

    get documents_path(type: "spec")
    assert_response :success
    assert_match "Spec One", response.body
    assert_select "section[aria-label='Document navigation'] h2", text: "Draft One", count: 0

    get documents_path(type: "plan_tracker")
    assert_response :success
    assert_match "Plan One", response.body
    assert_select "section[aria-label='Document navigation'] h2", text: "Draft One", count: 0
  end

  test "index renders type navigation cards" do
    admin = create_admin_user!
    project = create_project(key: "docs-card-nav")
    create_board(project_key: "docs-card-nav", project: project)
    sign_in_as(admin)

    patch current_project_path, params: { project_id: project.id }
    get documents_path
    assert_response :success
    assert_match "artifact-type-nav", response.body
    assert_match "Drafts", response.body
    assert_match "Specs", response.body
    assert_match "Plan Trackers", response.body
    assert_match "href=\"#{ERB::Util.html_escape(documents_path(project_id: project.id, type: "draft"))}\"", response.body
  end

  test "spec and plan_tracker cannot be edited in phase one" do
    admin = create_admin_user!
    sign_in_as(admin)
    draft = create_document(artifact_type: "draft", title: "Draft for Spec", body: "draft")
    spec = create_document(project: draft.project, artifact_type: "spec", title: "Spec Locked", body: "spec", source_draft: draft, editable: false)
    plan = create_document(artifact_type: "plan_tracker", title: "Plan Locked", body: "plan", editable: false)

    get edit_document_path(spec)
    assert_redirected_to document_path(spec)

    patch document_path(spec), params: { document: { title: "Changed" } }
    assert_redirected_to document_path(spec)
    assert_equal "Spec Locked", spec.reload.title

    get edit_document_path(plan)
    assert_redirected_to document_path(plan)
  end

  test "show renders related artifacts section and linked entries" do
    admin = create_admin_user!
    sign_in_as(admin)
    draft = create_document(artifact_type: "draft", title: "Draft Base", body: "draft")
    spec = create_document(project: draft.project, artifact_type: "spec", title: "Spec Derived", body: "spec", source_draft: draft, editable: false)
    plan = create_document(artifact_type: "plan_tracker", title: "Plan Linked", body: "plan", editable: false)
    DocumentRelation.create!(from_artifact: spec, to_artifact: draft, relation_type: "derives_from")
    DocumentRelation.create!(from_artifact: spec, to_artifact: plan, relation_type: "tracks")

    get document_path(spec)
    assert_response :success
    assert_match "Related Documents", response.body
    assert_match "derives_from:", response.body
    assert_match "Draft Base (draft)", response.body
    assert_match "tracks:", response.body
    assert_match "Plan Linked (plan_tracker)", response.body
  end

  test "index can be scoped by project_id" do
    admin = create_admin_user!
    sign_in_as(admin)
    project_a = create_project(key: "docs-scope-a")
    project_b = create_project(key: "docs-scope-b")
    create_document(project: project_a, artifact_type: "draft", title: "Draft A", body: "A")
    create_document(project: project_b, artifact_type: "draft", title: "Draft B", body: "B")

    get documents_path(type: "draft", project_id: project_a.id)
    assert_response :success
    assert_match "Draft A", response.body
    refute_match "Draft B", response.body
  end
end
