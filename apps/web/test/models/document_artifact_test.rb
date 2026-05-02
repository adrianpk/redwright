require "test_helper"

class DocumentArtifactTest < ActiveSupport::TestCase
  test "draft is valid without source_draft" do
    artifact = DocumentArtifact.new(
      project: create_project(key: "doc-draft-valid"),
      artifact_type: "draft",
      title: "Draft One",
      body: "Initial content"
    )

    assert artifact.valid?
  end

  test "spec requires source draft" do
    artifact = DocumentArtifact.new(
      project: create_project(key: "doc-spec-requires-source"),
      artifact_type: "spec",
      title: "Spec One",
      body: "Formalized content"
    )

    assert_not artifact.valid?
    assert_includes artifact.errors[:source_draft], "is required for spec artifacts"
  end

  test "spec source must be a draft artifact" do
    plan = create_document_artifact(
      artifact_type: "plan_tracker",
      title: "Plan",
      body: "Execution plan",
      editable: false
    )
    artifact = DocumentArtifact.new(
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
    draft = create_document_artifact(
      artifact_type: "draft",
      title: "Draft One",
      body: "Initial content"
    )

    relation = DocumentArtifactRelation.new(
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
    draft = create_document_artifact(
      artifact_type: "draft",
      title: "Feature Draft",
      body: "Draft details"
    )

    link = TicketArtifactLink.create!(ticket: ticket, document_artifact: draft, role: "reference")
    assert_equal 1, ticket.reload.document_artifacts.count
    assert_equal draft.id, ticket.document_artifacts.first.id
    assert_equal "reference", link.role
  end

  test "related_artifacts returns outgoing and incoming relation edges" do
    draft = create_document_artifact(
      artifact_type: "draft",
      title: "Draft Base",
      body: "Draft details"
    )
    spec = create_document_artifact(
      project: draft.project,
      artifact_type: "spec",
      title: "Spec Derived",
      body: "Spec details",
      source_draft: draft,
      editable: false
    )
    plan = create_document_artifact(
      artifact_type: "plan_tracker",
      title: "Plan Linked",
      body: "Plan details",
      editable: false
    )

    DocumentArtifactRelation.create!(from_artifact: spec, to_artifact: draft, relation_type: "derives_from")
    DocumentArtifactRelation.create!(from_artifact: spec, to_artifact: plan, relation_type: "tracks")

    pairs = spec.related_artifacts.map { |relation_type, artifact| [relation_type, artifact.id] }
    assert_includes pairs, [ "derives_from", draft.id ]
    assert_includes pairs, [ "tracks", plan.id ]
  end

  test "spec source_draft must be in the same project" do
    project_a = create_project(key: "doc-proj-a")
    project_b = create_project(key: "doc-proj-b")
    draft = create_document_artifact(project: project_a, artifact_type: "draft", title: "Draft A")

    artifact = DocumentArtifact.new(
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
end
