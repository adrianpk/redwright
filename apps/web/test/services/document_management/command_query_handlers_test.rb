require "test_helper"

module DocumentManagement
  class CommandQueryHandlersTest < ActiveSupport::TestCase
    test "creates updates lists and promotes project documents through dispatcher" do
      project = create_project(key: "document-api-#{SecureRandom.hex(4)}")
      use_case = create_use_case(project: project, name: "Billing")
      checkout = create_use_case(project: project, name: "Checkout")
      dispatcher = CommandQuery::ApplicationDispatcher.build

      created = dispatcher.call(command("CreateDocument", {
        project_id: project.id,
        title: "Project Draft",
        body: "Initial body",
        use_case_id: use_case.id
      }, request_id: "req-doc-create"))

      assert created.ok?, created.errors.inspect
      draft = Document.find(created.data.fetch("document_id"))
      assert_equal "draft", draft.artifact_type
      assert_equal true, draft.editable
      assert_equal use_case.id, draft.use_case_id
      assert_equal use_case.id, created.data.fetch("document").fetch("use_case_id")
      assert_equal "Billing", created.data.fetch("document").fetch("use_case_name")

      updated = dispatcher.call(command("UpdateDraftDocument", {
        document_id: draft.id,
        title: "Project Draft Updated",
        body: "Updated body",
        use_case_id: checkout.id
      }, request_id: "req-doc-update"))

      assert updated.ok?, updated.errors.inspect
      assert_equal "Project Draft Updated", draft.reload.title
      assert_equal checkout.id, draft.use_case_id

      listed = dispatcher.call(query("GetDocumentsByProject", {
        project_id: project.id,
        artifact_type: "draft"
      }, request_id: "req-doc-list"))

      assert listed.ok?, listed.errors.inspect
      assert_equal [draft.id], listed.data.fetch("documents").map { |item| item.fetch("id") }
      assert_equal checkout.id, listed.data.fetch("documents").first.fetch("use_case_id")

      promoted = dispatcher.call(command("PromoteDraftToSpec", {
        document_id: draft.id
      }, request_id: "req-doc-promote"))

      assert promoted.ok?, promoted.errors.inspect
      spec = Document.find(promoted.data.fetch("document_id"))
      assert_equal "spec", spec.artifact_type
      assert_equal draft.id, spec.source_draft_id
      assert_equal false, spec.editable
      assert_equal "document_promoted", promoted.effects.first.fetch("type")
    end

    test "clears draft use case through dispatcher" do
      project = create_project(key: "document-api-clear-use-case-#{SecureRandom.hex(4)}")
      use_case = create_use_case(project: project, name: "Billing")
      draft = create_document(project: project, use_case: use_case, title: "Scoped Draft")

      result = CommandQuery::ApplicationDispatcher.build.call(command("UpdateDraftDocument", {
        document_id: draft.id,
        use_case_id: ""
      }, request_id: "req-doc-clear-use-case"))

      assert result.ok?, result.errors.inspect
      assert_nil draft.reload.use_case_id
      assert_nil result.data.fetch("document").fetch("use_case_id")
    end

    test "rejects cross-project document use case through dispatcher" do
      project = create_project(key: "document-api-cross-use-case-#{SecureRandom.hex(4)}")
      other_project = create_project(key: "document-api-cross-use-case-other-#{SecureRandom.hex(4)}")
      foreign_use_case = create_use_case(project: other_project, name: "Foreign")

      result = CommandQuery::ApplicationDispatcher.build.call(command("CreateDocument", {
        project_id: project.id,
        title: "Invalid Draft",
        body: "Invalid body",
        use_case_id: foreign_use_case.id
      }, request_id: "req-doc-cross-use-case"))

      assert result.error?
      assert_equal "invalid_use_case", result.errors.first.fetch(:code)
    end

    test "rejects updating non-draft document" do
      project = create_project(key: "document-api-readonly-#{SecureRandom.hex(4)}")
      draft = create_document(project: project, title: "Draft")
      spec = create_document(project: project, artifact_type: "spec", title: "Spec", body: "Spec body", source_draft: draft, editable: false)

      result = CommandQuery::ApplicationDispatcher.build.call(command("UpdateDraftDocument", {
        document_id: spec.id,
        title: "Illegal update"
      }, request_id: "req-doc-readonly"))

      assert result.error?
      assert_equal "document_not_editable", result.errors.first.fetch(:code)
      assert_equal "Spec", spec.reload.title
    end

    private

    def command(name, payload, request_id:)
      envelope("command", name, payload, request_id: request_id)
    end

    def query(name, payload, request_id:)
      envelope("query", name, payload, request_id: request_id)
    end

    def envelope(kind, name, payload, request_id:)
      {
        "kind" => kind,
        "name" => name,
        "payload" => payload,
        "execution_context" => {"actor_identifier" => "test:documents", "source_channel" => "test"},
        "request_id" => request_id
      }
    end
  end
end
