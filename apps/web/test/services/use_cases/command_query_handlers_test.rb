require "test_helper"

module UseCases
  class CommandQueryHandlersTest < ActiveSupport::TestCase
    test "creates updates gets lists and deletes use cases through dispatcher" do
      project = create_project(key: "use-case-api-#{SecureRandom.hex(4)}")
      dispatcher = CommandQuery::ApplicationDispatcher.build

      created = dispatcher.call(command("CreateUseCase", {
        project_id: project.id,
        name: "Billing Flow",
        description: "Manage invoice and payment behavior."
      }, request_id: "req-use-case-create"))

      assert created.ok?, created.errors.inspect
      use_case = UseCase.find(created.data.fetch("use_case_id"))
      assert_equal "Billing Flow", use_case.name
      assert_equal "billing-flow", use_case.slug
      assert_equal "use_case_created", created.effects.first.fetch("type")

      updated = dispatcher.call(command("UpdateUseCase", {
        use_case_id: use_case.id,
        name: "Invoice Flow",
        description: "Manage invoice lifecycle behavior."
      }, request_id: "req-use-case-update"))

      assert updated.ok?, updated.errors.inspect
      use_case.reload
      assert_equal "Invoice Flow", use_case.name
      assert_equal "invoice-flow", use_case.slug
      assert_equal "Manage invoice lifecycle behavior.", use_case.description
      assert_equal "use_case_updated", updated.effects.first.fetch("type")

      retrieved = dispatcher.call(query("GetUseCase", {
        project_id: project.id,
        slug: "invoice-flow"
      }, request_id: "req-use-case-get"))

      assert retrieved.ok?, retrieved.errors.inspect
      assert_equal use_case.id, retrieved.data.fetch("use_case_id")
      assert_equal "Invoice Flow", retrieved.data.fetch("use_case").fetch("name")
      assert_equal 0, retrieved.data.fetch("metrics").fetch("tickets")

      create_use_case(project: project, name: "Support")
      listed = dispatcher.call(query("ListUseCases", {
        project_id: project.id
      }, request_id: "req-use-case-list"))

      assert listed.ok?, listed.errors.inspect
      assert_equal 2, listed.data.fetch("count")
      assert_equal ["Support", "Invoice Flow"], listed.data.fetch("use_cases").map { |item| item.fetch("name") }

      deleted = dispatcher.call(command("DeleteUseCase", {
        use_case_id: use_case.id
      }, request_id: "req-use-case-delete"))

      assert deleted.ok?, deleted.errors.inspect
      assert_equal "use_case_deleted", deleted.effects.first.fetch("type")
      assert_nil UseCase.find_by(id: use_case.id)
    end

    test "returns validation errors for invalid create and update payloads" do
      project = create_project(key: "use-case-api-invalid-#{SecureRandom.hex(4)}")
      existing = create_use_case(project: project, name: "Billing")
      dispatcher = CommandQuery::ApplicationDispatcher.build

      missing_description = dispatcher.call(command("CreateUseCase", {
        project_id: project.id,
        name: "Checkout"
      }, request_id: "req-use-case-missing-description"))

      assert missing_description.error?
      assert_equal "invalid_description", missing_description.errors.first.fetch(:code)

      duplicate = dispatcher.call(command("CreateUseCase", {
        project_id: project.id,
        name: "Billing",
        description: "Duplicate billing."
      }, request_id: "req-use-case-duplicate"))

      assert duplicate.error?
      assert_includes duplicate.errors.map { |error| error.fetch(:code) }, "invalid_name"
      assert_includes duplicate.errors.map { |error| error.fetch(:code) }, "invalid_slug"

      empty_update = dispatcher.call(command("UpdateUseCase", {
        use_case_id: existing.id
      }, request_id: "req-use-case-empty-update"))

      assert empty_update.error?
      assert_equal "invalid_payload", empty_update.errors.first.fetch(:code)
      assert_equal "Billing", existing.reload.name
    end

    test "returns structured not found errors" do
      project = create_project(key: "use-case-api-missing-#{SecureRandom.hex(4)}")
      dispatcher = CommandQuery::ApplicationDispatcher.build

      missing_project = dispatcher.call(command("CreateUseCase", {
        project_id: project.id + 1000,
        name: "Billing",
        description: "Billing behavior."
      }, request_id: "req-use-case-missing-project"))

      assert missing_project.error?
      assert_equal "project_not_found", missing_project.errors.first.fetch(:code)

      missing_use_case = dispatcher.call(query("GetUseCase", {
        project_id: project.id,
        slug: "missing"
      }, request_id: "req-use-case-missing"))

      assert missing_use_case.error?
      assert_equal "use_case_not_found", missing_use_case.errors.first.fetch(:code)
    end

    test "blocks delete with structured reference counts" do
      project = create_project(key: "use-case-api-blocked-#{SecureRandom.hex(4)}")
      use_case = create_use_case(project: project, name: "Billing")
      create_document(project: project, use_case: use_case)
      dispatcher = CommandQuery::ApplicationDispatcher.build

      result = dispatcher.call(command("DeleteUseCase", {
        use_case_id: use_case.id
      }, request_id: "req-use-case-blocked-delete"))

      assert result.error?
      assert_equal "use_case_delete_blocked", result.errors.first.fetch(:code)
      assert_equal use_case.id, result.data.fetch("use_case_id")
      assert_equal 1, result.data.fetch("blocking_references").fetch("documents")
      assert UseCase.exists?(use_case.id)
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
        "execution_context" => {"actor_identifier" => "test:use-cases", "source_channel" => "test"},
        "request_id" => request_id
      }
    end
  end
end
