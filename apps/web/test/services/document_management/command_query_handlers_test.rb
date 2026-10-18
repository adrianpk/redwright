require "test_helper"

class DocumentManagementCommandQueryHandlersTest < ActiveSupport::TestCase
  test "command API creates and approves one file backed specification" do
    original = create_document
    project = original.project
    dispatcher = CommandQuery::ApplicationDispatcher.build
    feature = create_use_case(project: project, name: "API feature")
    create = dispatcher.call(message("CreateSpecification", {project_id: project.id, use_case_id: feature.id, title: "API feature", body: "Expected behavior"}))
    assert create.ok?, create.errors.inspect
    id = create.data.fetch("document_id")
    revision = create.data.fetch("document").fetch("source_hash")
    approval = dispatcher.call(message("ApproveSpecification", {document_id: id, revision: revision}))
    assert approval.ok?, approval.errors.inspect
    assert_equal id, approval.data.fetch("document_id")
    assert_equal "approved", Document.find(id).source[:metadata]["status"]
    assert_equal 2, project.documents.count
  end

  test "query refreshes files and excludes internal artifacts" do
    document = create_document
    create_document(project: document.project, artifact_type: "plan_tracker", status: "tracking")
    path = Pathname.new(document.project.root_path).join(document.relative_path)
    path.write(path.read.sub(document.title, "External title"))
    query = message("GetSpecificationsByProject", {project_id: document.project_id}).merge("kind" => "query")
    result = CommandQuery::ApplicationDispatcher.build.call(query)
    assert result.ok?, result.errors.inspect
    assert_equal 1, result.data.fetch("count")
    assert_equal "External title", result.data.fetch("documents").first.fetch("title")
  end

  private

  def message(name, payload)
    {kind: "command", name: name, payload: payload, request_id: SecureRandom.uuid, execution_context: {}}.deep_stringify_keys
  end
end
