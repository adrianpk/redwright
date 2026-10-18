require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  test "files own content and status while the database contains only an index" do
    # External edits must survive reconciliation rather than be overwritten by cached state.
    document = create_document(title: "Billing", body: "Original")
    path = Pathname.new(document.project.root_path).join(document.relative_path)
    path.write(path.read.sub("Original", "Externally edited").sub("status: draft", "status: approved"))
    Document.reconcile!(document.project)
    assert_equal "approved", document.reload.status
    assert_equal "Externally edited", document.body
    assert_not_includes Document.column_names, "body"
    assert_not_includes Document.column_names, "editable"
    assert_not_includes Document.column_names, "source_draft_id"
  end

  test "portable project identifiers survive indexing and approval" do
    document = create_document
    entry = document.source
    store = Specifications::FileStore.new(document.project)
    store.write(path: document.relative_path, metadata: entry[:metadata].merge("project_id" => "portable-project"), body: entry[:body], revision: document.source_hash)
    Document.reconcile!(document.project)
    document.reload.approve!(revision: document.source_hash)
    assert_equal "portable-project", document.source[:metadata]["project_id"]
    assert_equal "approved", document.status
  end

  test "metadata changes preserve meaningful Markdown indentation" do
    # Leading indentation can change Markdown prose into code.
    body = "    code example\n\nA final paragraph.\n\n"
    document = create_document(body: body)
    document.approve!(revision: document.source_hash)
    assert_equal body, document.body
  end

  test "approval updates the same file and specification identity" do
    document = create_document(body: "Under review")
    original_path, original_id = document.relative_path, document.id
    assert_no_difference "Document.count" do
      document.approve!(revision: document.source_hash)
    end
    assert_equal original_id, document.id
    assert_equal original_path, document.relative_path
    assert_equal "approved", document.source[:metadata]["status"]
    assert_equal "Under review", document.body
  end

  test "stale edits and approval cannot overwrite external changes" do
    document = create_document
    old_hash = document.source_hash
    path = Pathname.new(document.project.root_path).join(document.relative_path)
    path.write(path.read + "\nExternal decision\n")
    error = assert_raises(Specifications::Error) { document.approve!(revision: old_hash) }
    assert_equal :conflict, error.code
    assert_includes path.read, "External decision"
  end

  test "one feature has one specification and corrective work has its own case" do
    first = create_document
    use_case = create_use_case(project: first.project)
    first.update!(use_case: use_case)
    assert_raises(ActiveRecord::RecordInvalid) { create_document(project: first.project, use_case: use_case, title: "Duplicate specification") }
    corrective_case = create_use_case(project: first.project, name: "Billing correction", corrects_use_case: use_case)
    second = create_document(project: first.project, use_case: corrective_case, title: "Corrective specification")
    assert_equal [first.id], use_case.documents.specifications.pluck(:id)
    assert_equal use_case.id, second.use_case.corrects_use_case_id
    other_case = create_use_case(name: "Foreign case")
    assert_not first.update(use_case: other_case)
  end

  test "renaming a use case preserves specification file references" do
    specification = create_document
    use_case = create_use_case(project: specification.project, name: "Billing")
    specification.update!(use_case: use_case)
    path = specification.relative_path
    use_case.update!(name: "Invoice Billing")
    Document.reconcile!(specification.project)
    assert_equal "billing", use_case.slug
    assert_equal use_case.id, specification.reload.use_case_id
    assert_equal path, specification.relative_path
    quiz = QuizLoops::Runtime.new(project: specification.project, use_case_name: use_case.name).open.quiz
    assert_equal use_case.id, quiz.use_case_id
  end

  test "reconciliation discovers added files and removes deleted entries without recreating files" do
    first = create_document
    second = create_document(project: first.project, title: "Another feature")
    path = Pathname.new(first.project.root_path).join(first.relative_path)
    path.delete
    Document.reconcile!(first.project)
    assert_not Document.exists?(first.id)
    assert Document.exists?(second.id)
    assert_not path.exist?
    second.delete
    Document.reconcile!(first.project)
    assert_equal 1, first.project.documents.specifications.count
  end

  test "invalid files and escaping symlinks do not replace the index" do
    document = create_document
    path = Pathname.new(document.project.root_path).join(document.relative_path)
    path.write("---\nstatus: [broken\n---\nBody")
    assert_raises(Specifications::Error) { Document.reconcile!(document.project) }
    assert Document.exists?(document.id)
    path.delete
    external = Tempfile.new("external-spec")
    external.write("Private source")
    external.close
    File.symlink(external.path, path)
    assert_raises(Specifications::Error) { Document.reconcile!(document.project) }
    assert_equal "Private source", File.read(external.path)
  ensure
    external&.unlink
  end

  test "relations are reconstructed from the source files" do
    first = create_document
    second = create_document(project: first.project)
    DocumentRelation.create!(from_artifact: second, to_artifact: first, relation_type: "references")
    DocumentRelation.delete_all
    Document.reconcile!(first.project)
    assert_equal [["references", first.id]], second.related_documents.map { |kind, doc| [kind, doc.id] }
  end
end
