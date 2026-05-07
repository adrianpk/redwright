module DocumentManagement
  class CommandQueryHandlers
    include CommandQuery::PayloadReader

    def self.register(dispatcher)
      new.register(dispatcher)
    end

    def register(dispatcher)
      dispatcher.register_command("CreateDocument", method(:create_document))
      dispatcher.register_command("UpdateDraftDocument", method(:update_draft_document))
      dispatcher.register_command("PromoteDraftToSpec", method(:promote_draft_to_spec))
      dispatcher.register_query("GetDocumentsByProject", method(:get_documents_by_project))
      dispatcher
    end

    def create_document(payload:, context:, request_id:)
      project = find_project(value_from(payload, "project_id"))
      return missing_project_result(request_id: request_id) unless project

      document = Document.new(
        project: project,
        artifact_type: "draft",
        editable: true,
        title: value_from(payload, "title").to_s.strip,
        body: value_from(payload, "body").to_s,
        use_case_id: value_from(payload, "use_case_id")
      )
      return invalid_record_result(document, request_id: request_id, summary: "Document could not be created.") unless document.save

      CommandQuery::Result.ok(
        request_id: request_id,
        data: document_result_data(document, summary: "Document draft created."),
        effects: [
          {
            "type" => "document_created",
            "document_id" => document.id,
            "project_id" => project.id,
            "artifact_type" => document.artifact_type
          }
        ]
      )
    end

    def update_draft_document(payload:, context:, request_id:)
      document = find_document(value_from(payload, "document_id"))
      return missing_document_result(request_id: request_id) unless document
      return readonly_document_result(document, request_id: request_id) unless document.artifact_type == "draft"

      attrs = {}
      attrs[:title] = value_from(payload, "title").to_s.strip if key_present?(payload, "title")
      attrs[:body] = value_from(payload, "body").to_s if key_present?(payload, "body")
      attrs[:use_case_id] = value_from(payload, "use_case_id") if key_present?(payload, "use_case_id")
      return invalid_payload_result(request_id: request_id, message: "title, body, or use_case_id is required") if attrs.empty?
      return invalid_record_result(document, request_id: request_id, summary: "Document draft could not be updated.") unless document.update(attrs)

      CommandQuery::Result.ok(
        request_id: request_id,
        data: document_result_data(document.reload, summary: "Document draft updated."),
        effects: [
          {
            "type" => "document_updated",
            "document_id" => document.id,
            "project_id" => document.project_id
          }
        ]
      )
    end

    def promote_draft_to_spec(payload:, context:, request_id:)
      draft = find_document(value_from(payload, "document_id"))
      return missing_document_result(request_id: request_id) unless draft
      return readonly_document_result(draft, request_id: request_id) unless draft.artifact_type == "draft"

      spec = DocumentPromotionService.new(draft: draft).call
      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "summary" => "Document draft promoted to spec.",
          "document_id" => spec.id,
          "project_id" => spec.project_id,
          "document" => document_data(spec),
          "source_document_id" => draft.id
        },
        effects: [
          {
            "type" => "document_promoted",
            "document_id" => spec.id,
            "source_document_id" => draft.id,
            "project_id" => spec.project_id
          }
        ]
      )
    rescue DocumentPromotionService::PromotionError => e
      CommandQuery::Result.error(
        request_id: request_id,
        code: "document_promotion_failed",
        message: e.message
      )
    end

    def get_documents_by_project(payload:, context:, request_id:)
      project = find_project(value_from(payload, "project_id"))
      return missing_project_result(request_id: request_id) unless project

      documents = project.documents.order(updated_at: :desc, created_at: :desc)
      artifact_type = value_from(payload, "artifact_type", "type").to_s
      documents = documents.by_type(artifact_type) if Document::TYPES.include?(artifact_type)

      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "summary" => "Project documents retrieved.",
          "project_id" => project.id,
          "documents" => documents.map { |document| document_data(document) },
          "count" => documents.count
        },
        effects: []
      )
    end

    private

    def document_result_data(document, summary:)
      {
        "summary" => summary,
        "document_id" => document.id,
        "project_id" => document.project_id,
        "document" => document_data(document)
      }
    end

    def document_data(document)
      {
        "id" => document.id,
        "project_id" => document.project_id,
        "artifact_type" => document.artifact_type,
        "title" => document.title,
        "body" => document.body,
        "editable" => document.editable,
        "source_draft_id" => document.source_draft_id,
        "use_case_id" => document.use_case_id,
        "use_case_name" => document.use_case&.name
      }
    end

    def invalid_record_result(record, request_id:, summary:)
      CommandQuery::Result.new(
        status: "error",
        request_id: request_id,
        data: {"summary" => summary},
        effects: [],
        errors: record_errors(record)
      )
    end

    def readonly_document_result(document, request_id:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "document_not_editable",
        message: "only draft documents are editable",
        details: {"document_id" => document.id, "artifact_type" => document.artifact_type}
      )
    end

    def invalid_payload_result(request_id:, message:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "invalid_payload",
        message: message
      )
    end

    def missing_project_result(request_id:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "project_not_found",
        message: "project was not found"
      )
    end

    def missing_document_result(request_id:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "document_not_found",
        message: "document was not found"
      )
    end

    def record_errors(record)
      record.errors.map do |error|
        {
          code: "invalid_#{error.attribute}",
          message: "#{error.attribute} #{error.message}",
          details: {"attribute" => error.attribute.to_s}
        }
      end
    end

    def find_project(project_id)
      return nil if project_id.blank?

      Project.find_by(id: project_id)
    end

    def find_document(document_id)
      return nil if document_id.blank?

      Document.find_by(id: document_id)
    end

  end
end
