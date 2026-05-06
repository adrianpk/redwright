module UseCases
  class CommandQueryHandlers
    def self.register(dispatcher)
      new.register(dispatcher)
    end

    def register(dispatcher)
      dispatcher.register_command("CreateUseCase", method(:create_use_case))
      dispatcher.register_command("UpdateUseCase", method(:update_use_case))
      dispatcher.register_command("DeleteUseCase", method(:delete_use_case))
      dispatcher.register_query("ListUseCases", method(:list_use_cases))
      dispatcher.register_query("GetUseCase", method(:get_use_case))
      dispatcher
    end

    private

    def create_use_case(payload:, context:, request_id:)
      project = find_project(value_from(payload, "project_id"))
      return missing_project_result(request_id: request_id) unless project

      use_case = project.use_cases.new(
        name: value_from(payload, "name").to_s.strip,
        description: value_from(payload, "description").to_s.strip
      )
      return invalid_record_result(use_case, request_id: request_id, summary: "Use case could not be created.") unless use_case.save

      CommandQuery::Result.ok(
        request_id: request_id,
        data: use_case_result_data(use_case, summary: "Use case created."),
        effects: [
          {
            "type" => "use_case_created",
            "use_case_id" => use_case.id,
            "project_id" => project.id
          }
        ]
      )
    end

    def update_use_case(payload:, context:, request_id:)
      use_case = find_use_case_for_payload(payload)
      return missing_use_case_result(request_id: request_id) unless use_case

      attrs = {}
      attrs[:name] = value_from(payload, "name").to_s.strip if key_present?(payload, "name")
      attrs[:description] = value_from(payload, "description").to_s.strip if key_present?(payload, "description")
      return invalid_payload_result(request_id: request_id, message: "name or description is required") if attrs.empty?
      return invalid_record_result(use_case, request_id: request_id, summary: "Use case could not be updated.") unless use_case.update(attrs)

      CommandQuery::Result.ok(
        request_id: request_id,
        data: use_case_result_data(use_case.reload, summary: "Use case updated."),
        effects: [
          {
            "type" => "use_case_updated",
            "use_case_id" => use_case.id,
            "project_id" => use_case.project_id
          }
        ]
      )
    end

    def delete_use_case(payload:, context:, request_id:)
      use_case = find_use_case_for_payload(payload)
      return missing_use_case_result(request_id: request_id) unless use_case

      if use_case.deletion_blocked?
        return CommandQuery::Result.new(
          status: "error",
          request_id: request_id,
          data: {
            "summary" => "Use case could not be deleted.",
            "use_case_id" => use_case.id,
            "project_id" => use_case.project_id,
            "blocking_references" => use_case.blocking_reference_counts
          },
          effects: [],
          errors: [
            {
              code: "use_case_delete_blocked",
              message: "use case has blocking references",
              details: {
                "use_case_id" => use_case.id,
                "project_id" => use_case.project_id,
                "blocking_references" => use_case.blocking_reference_counts
              }
            }
          ]
        )
      end

      use_case_id = use_case.id
      project_id = use_case.project_id
      use_case.destroy!

      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "summary" => "Use case deleted.",
          "use_case_id" => use_case_id,
          "project_id" => project_id
        },
        effects: [
          {
            "type" => "use_case_deleted",
            "use_case_id" => use_case_id,
            "project_id" => project_id
          }
        ]
      )
    rescue ActiveRecord::RecordNotDestroyed => e
      CommandQuery::Result.error(
        request_id: request_id,
        code: "use_case_delete_blocked",
        message: e.message
      )
    end

    def list_use_cases(payload:, context:, request_id:)
      project = find_project(value_from(payload, "project_id"))
      return missing_project_result(request_id: request_id) unless project

      use_cases = project.use_cases.order(created_at: :desc, id: :desc)
      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "summary" => "Project use cases retrieved.",
          "project_id" => project.id,
          "use_cases" => use_cases.map { |use_case| use_case_data(use_case) },
          "count" => use_cases.count
        },
        effects: []
      )
    end

    def get_use_case(payload:, context:, request_id:)
      use_case = find_use_case_for_payload(payload)
      return missing_use_case_result(request_id: request_id) unless use_case

      CommandQuery::Result.ok(
        request_id: request_id,
        data: use_case_result_data(use_case, summary: "Use case retrieved.", include_metrics: true),
        effects: []
      )
    end

    def use_case_result_data(use_case, summary:, include_metrics: false)
      data = {
        "summary" => summary,
        "use_case_id" => use_case.id,
        "project_id" => use_case.project_id,
        "use_case" => use_case_data(use_case)
      }
      data["metrics"] = metrics_for(use_case) if include_metrics
      data
    end

    def use_case_data(use_case)
      {
        "id" => use_case.id,
        "project_id" => use_case.project_id,
        "name" => use_case.name,
        "description" => use_case.description,
        "slug" => use_case.slug,
        "created_at" => use_case.created_at&.iso8601,
        "updated_at" => use_case.updated_at&.iso8601
      }
    end

    def metrics_for(use_case)
      document_counts = use_case.documents.group(:artifact_type).count.transform_keys(&:to_s)
      {
        "tickets" => use_case.tickets.count,
        "documents" => document_counts,
        "plans" => document_counts.fetch("plan_tracker", 0),
        "quiz_entries" => use_case.quiz_entries.count,
        "blocking_references" => use_case.blocking_reference_counts
      }
    end

    def find_use_case_for_payload(payload)
      use_case_id = value_from(payload, "use_case_id", "id")
      return UseCase.find_by(id: use_case_id) if use_case_id.present?

      project = find_project(value_from(payload, "project_id"))
      slug = value_from(payload, "slug").to_s.strip
      return nil unless project && slug.present?

      project.use_cases.find_by(slug: slug)
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

    def missing_use_case_result(request_id:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "use_case_not_found",
        message: "use case was not found"
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

    def key_present?(hash, key)
      source = hash_from(hash)
      source.key?(key.to_s) || source.key?(key.to_sym)
    end

    def value_from(hash, *keys)
      source = hash_from(hash)
      keys.each do |key|
        return source[key.to_s] if source.key?(key.to_s)
        return source[key.to_sym] if source.key?(key.to_sym)
      end
      nil
    end

    def hash_from(value)
      value.is_a?(Hash) ? value : {}
    end
  end
end
