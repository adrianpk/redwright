module DocumentManagement
  class CommandQueryHandlers
    include CommandQuery::PayloadReader

    def self.register(dispatcher)
      new.register(dispatcher)
    end

    def register(dispatcher)
      dispatcher.register_command("CreateSpecification", method(:create_specification))
      dispatcher.register_command("UpdateSpecification", method(:update_specification))
      dispatcher.register_command("ApproveSpecification", method(:approve_specification))
      dispatcher.register_command("GenerateSpecification", method(:generate_specification))
      dispatcher.register_command("BuildSpecificationTickets", method(:build_tickets))
      dispatcher.register_query("GetSpecificationsByProject", method(:list_specifications))
      dispatcher
    end

    def create_specification(payload:, context:, request_id:)
      perform(request_id) do
        project = Project.find(value_from(payload, "project_id"))
        document = project.documents.create!(title: value_from(payload, "title"), body: value_from(payload, "body"),
          artifact_type: "spec", status: value_from(payload, "status").presence || "draft", use_case_id: value_from(payload, "use_case_id"))
        result(document, request_id)
      end
    end

    def update_specification(payload:, context:, request_id:)
      perform(request_id) do
        document = find_specification(payload)
        document.revision = value_from(payload, "revision").presence || raise(Specifications::Error, "Source revision is required.")
        attributes = %w[title body use_case_id].each_with_object({}) { |key, values| values[key] = value_from(payload, key) if key_present?(payload, key) }
        document.revise!(attributes: attributes.merge(status: "draft"), revision: document.revision)
        result(document, request_id)
      end
    end

    def approve_specification(payload:, context:, request_id:)
      perform(request_id) do
        document = find_specification(payload)
        revision = value_from(payload, "revision").presence || raise(Specifications::Error, "Source revision is required.")
        document.approve!(revision: revision)
        result(document, request_id)
      end
    end

    def generate_specification(payload:, context:, request_id:)
      perform(request_id) do
        project = Project.find(value_from(payload, "project_id"))
        use_case = project.use_cases.find(value_from(payload, "use_case_id")) if value_from(payload, "use_case_id").present?
        result(Specifications::Generator.new(project: project, use_case: use_case, feature: value_from(payload, "feature")).call, request_id)
      end
    end

    def list_specifications(payload:, context:, request_id:)
      perform(request_id) do
        project = Project.find(value_from(payload, "project_id"))
        documents = Document.reconcile!(project).specifications.order(source_modified_at: :desc)
        CommandQuery::Result.ok(request_id: request_id, data: {"project_id" => project.id, "documents" => documents.map { |document| data(document) }, "count" => documents.size})
      end
    end

    def build_tickets(payload:, context:, request_id:)
      perform(request_id) do
        document = find_specification(payload)
        entry = Specifications::Slicing.new(specification: document).call
        CommandQuery::Result.ok(request_id: request_id, data: {"document_id" => document.id, "ticket_keys" => entry[:metadata]["ticket_keys"]})
      end
    end

    private

    def find_specification(payload)
      document = Document.specifications.find(value_from(payload, "document_id"))
      Document.reconcile!(document.project)
      document.reload
    end

    def result(document, request_id)
      CommandQuery::Result.ok(request_id: request_id, data: {"summary" => "Specification saved.", "document_id" => document.id, "project_id" => document.project_id, "document" => data(document)})
    end

    def data(document)
      document.attributes.slice("id", "project_id", "title", "status", "relative_path", "source_hash", "use_case_id").merge("body" => document.body, "artifact_type" => "spec")
    end

    def perform(request_id)
      yield
    rescue ActiveRecord::RecordNotFound
      CommandQuery::Result.error(request_id: request_id, code: "specification_not_found", message: "Specification or project was not found.")
    rescue ActiveRecord::RecordInvalid, Specifications::Error => e
      code = e.respond_to?(:code) ? e.code : "invalid_specification"
      CommandQuery::Result.error(request_id: request_id, code: code, message: e.message)
    end
  end
end
