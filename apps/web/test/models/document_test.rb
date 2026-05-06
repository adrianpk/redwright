require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  test "draft is valid without source_draft" do
    artifact = Document.new(
      project: create_project(key: "doc-draft-valid"),
      artifact_type: "draft",
      title: "Draft One",
      body: "Initial content"
    )

    assert artifact.valid?
  end

  test "spec requires source draft" do
    artifact = Document.new(
      project: create_project(key: "doc-spec-requires-source"),
      artifact_type: "spec",
      title: "Spec One",
      body: "Formalized content"
    )

    assert_not artifact.valid?
    assert_includes artifact.errors[:source_draft], "is required for spec artifacts"
  end

  test "spec source must be a draft artifact" do
    plan = create_document(
      artifact_type: "plan_tracker",
      title: "Plan",
      body: "Execution plan",
      editable: false
    )
    artifact = Document.new(
      project: create_project(key: "doc-spec-source-must-be-draft"),
      artifact_type: "spec",
      title: "Spec One",
      body: "Formalized content",
      source_draft: plan
    )

    assert_not artifact.valid?
    assert_includes artifact.errors[:source_draft], "must reference a draft artifact"
  end

  test "relation rejects self-reference" do
    draft = create_document(
      artifact_type: "draft",
      title: "Draft One",
      body: "Initial content"
    )

    relation = DocumentRelation.new(
      from_artifact: draft,
      to_artifact: draft,
      relation_type: "references"
    )

    assert_not relation.valid?
    assert_includes relation.errors[:to_artifact], "must be different from from_artifact"
  end

  test "ticket can optionally link artifacts" do
    board = create_board(project_key: "factory-artifacts")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Implement feature")
    draft = create_document(
      project: board.project,
      artifact_type: "draft",
      title: "Feature Draft",
      body: "Draft details"
    )

    link = TicketDocumentLink.create!(ticket: ticket, document: draft, role: "reference")
    assert_equal 1, ticket.reload.documents.count
    assert_equal draft.id, ticket.documents.first.id
    assert_equal "reference", link.role
  end

  test "related_artifacts returns outgoing and incoming relation edges" do
    draft = create_document(
      artifact_type: "draft",
      title: "Draft Base",
      body: "Draft details"
    )
    spec = create_document(
      project: draft.project,
      artifact_type: "spec",
      title: "Spec Derived",
      body: "Spec details",
      source_draft: draft,
      editable: false
    )
    plan = create_document(
      artifact_type: "plan_tracker",
      title: "Plan Linked",
      body: "Plan details",
      editable: false
    )

    DocumentRelation.create!(from_artifact: spec, to_artifact: draft, relation_type: "derives_from")
    DocumentRelation.create!(from_artifact: spec, to_artifact: plan, relation_type: "tracks")

    pairs = spec.related_artifacts.map { |relation_type, artifact| [relation_type, artifact.id] }
    assert_includes pairs, [ "derives_from", draft.id ]
    assert_includes pairs, [ "tracks", plan.id ]
  end

  test "spec source_draft must be in the same project" do
    project_a = create_project(key: "doc-proj-a")
    project_b = create_project(key: "doc-proj-b")
    draft = create_document(project: project_a, artifact_type: "draft", title: "Draft A")

    artifact = Document.new(
      project: project_b,
      artifact_type: "spec",
      title: "Spec B",
      body: "Spec body",
      source_draft: draft,
      editable: false
    )

    assert_not artifact.valid?
    assert_includes artifact.errors[:source_draft], "must belong to the same project"
  end

  test "for_project scope isolates document artifacts by project" do
    project_a = create_project(key: "doc-scope-a")
    project_b = create_project(key: "doc-scope-b")
    artifact_a = create_document(project: project_a, title: "Artifact A")
    create_document(project: project_b, title: "Artifact B")

    scoped_ids = Document.for_project(project_a.id).pluck(:id)
    assert_equal [artifact_a.id], scoped_ids
  end

  test "can optionally belong to a use case in the same project" do
    project = create_project(key: "doc-use-case")
    use_case = create_use_case(project: project, name: "Billing")
    document = create_document(project: project, use_case: use_case, title: "Billing Draft")

    assert_equal use_case.id, document.use_case_id
    assert_equal [document.id], Document.for_use_case(use_case.id).pluck(:id)
  end

  test "use case must belong to document project" do
    project = create_project(key: "doc-use-case-project")
    other_project = create_project(key: "doc-use-case-other-project")
    other_use_case = create_use_case(project: other_project, name: "External")
    document = Document.new(
      project: project,
      use_case: other_use_case,
      artifact_type: "draft",
      title: "Invalid scoped draft",
      body: "Draft body"
    )

    assert_not document.valid?
    assert_includes document.errors[:use_case], "must belong to the same project"
  end

  test "draft must remain editable" do
    artifact = Document.new(
      project: create_project(key: "doc-draft-editable"),
      artifact_type: "draft",
      title: "Draft One",
      body: "Initial content",
      editable: false
    )

    assert_not artifact.valid?
    assert_includes artifact.errors[:editable], "must be true for draft artifacts"
  end

  test "spec must be read-only" do
    draft = create_document(artifact_type: "draft", title: "Draft One", body: "Draft body")
    artifact = Document.new(
      project: draft.project,
      artifact_type: "spec",
      title: "Spec One",
      body: "Spec content",
      source_draft: draft,
      editable: true
    )

    assert_not artifact.valid?
    assert_includes artifact.errors[:editable], "must be false for non-draft artifacts"
  end

  test "plan tracker must be read-only" do
    artifact = Document.new(
      project: create_project(key: "doc-plan-read-only"),
      artifact_type: "plan_tracker",
      title: "Plan One",
      body: "Plan content",
      editable: true
    )

    assert_not artifact.valid?
    assert_includes artifact.errors[:editable], "must be false for non-draft artifacts"
  end

  test "artifact_type is immutable after creation" do
    artifact = create_document(artifact_type: "draft", title: "Draft Mutable", body: "Draft content")

    updated = artifact.update(artifact_type: "plan_tracker", editable: false)

    assert_equal false, updated
    assert_includes artifact.errors[:artifact_type], "is immutable after creation"
    assert_equal "draft", artifact.reload.artifact_type
  end

  test "non-draft artifact cannot be updated to editable true" do
    draft = create_document(artifact_type: "draft", title: "Draft Source", body: "Draft body")
    spec = create_document(
      project: draft.project,
      artifact_type: "spec",
      title: "Spec Locked",
      body: "Spec content",
      source_draft: draft,
      editable: false
    )

    updated = spec.update(editable: true)

    assert_equal false, updated
    assert_includes spec.errors[:editable], "must be false for non-draft artifacts"
    assert_equal false, spec.reload.editable
  end
end
