module RuntimeContainers
  class CommandQueryHandlers
    def self.register(dispatcher)
      new.register(dispatcher)
    end

    def register(dispatcher)
      dispatcher.register_command("GenerateProjectRuntimeContainers", method(:generate_project_runtime_containers))
      dispatcher.register_command("RegenerateProjectRuntimeContainers", method(:regenerate_project_runtime_containers))
      dispatcher.register_command("UpdateProjectRuntimeContainers", method(:update_project_runtime_containers))
      dispatcher.register_command("RecordProjectRuntimeContainerValidation", method(:record_project_runtime_container_validation))
      dispatcher.register_command("MarkProjectRuntimeContainersReady", method(:mark_project_runtime_containers_ready))
      dispatcher.register_query("GetProjectRuntimeContainers", method(:get_project_runtime_containers))
      dispatcher
    end

    def generate_project_runtime_containers(payload:, context:, request_id:)
      project = find_project(value_from(payload, "project_id"))
      return missing_project_result(request_id: request_id) unless project

      result = GenerationService.new(project: project).call
      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "summary" => generation_summary(result),
          "project_id" => project.id,
          "runtime_containers" => result.runtime_container_state,
          "generated_runtime_containers" => result.generated_state,
          "generation" => generation_data(result)
        },
        effects: [
          {
            "type" => result.persisted? ? "runtime_containers_generated" : "runtime_containers_generation_suggested",
            "project_id" => project.id,
            "readiness" => result.generated_state.fetch("readiness"),
            "generator_source" => result.generator_source,
            "fallback_reason" => result.fallback_reason
          }
        ]
      )
    end

    def regenerate_project_runtime_containers(payload:, context:, request_id:)
      project = find_project(value_from(payload, "project_id"))
      return missing_project_result(request_id: request_id) unless project

      result = GenerationService.new(project: project, persist: false).call
      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "summary" => "Runtime Containers suggestion regenerated.",
          "project_id" => project.id,
          "runtime_containers" => result.runtime_container_state,
          "generated_runtime_containers" => result.generated_state,
          "comparison" => Comparison.new(
            active_state: result.runtime_container_state,
            proposed_state: result.generated_state
          ).to_h,
          "generation" => generation_data(result)
        },
        effects: [
          {
            "type" => "runtime_containers_generation_suggested",
            "project_id" => project.id,
            "readiness" => result.generated_state.fetch("readiness"),
            "generator_source" => result.generator_source,
            "fallback_reason" => result.fallback_reason
          }
        ]
      )
    end

    def update_project_runtime_containers(payload:, context:, request_id:)
      project = find_project(value_from(payload, "project_id"))
      return missing_project_result(request_id: request_id) unless project

      attributes = value_from(payload, "runtime_containers", "attributes")
      update = UpdateService.new(project: project, attributes: attributes).call
      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "summary" => "Runtime Containers updated.",
          "project_id" => project.id,
          "runtime_containers" => update.runtime_container.to_state,
          "changed_fields" => update.changed_fields
        },
        effects: [
          {
            "type" => "runtime_containers_updated",
            "project_id" => project.id,
            "runtime_container_id" => update.runtime_container.id,
            "changed_fields" => update.changed_fields
          }
        ]
      )
    rescue ActiveRecord::RecordInvalid => e
      invalid_record_result(e.record, request_id: request_id, summary: "Runtime Containers could not be updated.")
    end

    def record_project_runtime_container_validation(payload:, context:, request_id:)
      project = find_project(value_from(payload, "project_id"))
      return missing_project_result(request_id: request_id) unless project

      validation = ValidationService.new(
        project: project,
        status: value_from(payload, "validation_status", "status"),
        output_summary: value_from(payload, "validation_output_summary", "summary", "reason"),
        validation_command: value_from(payload, "validation_command")
      ).call

      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "summary" => "Runtime Containers validation recorded.",
          "project_id" => project.id,
          "runtime_containers" => validation.runtime_container.to_state,
          "changed_fields" => validation.changed_fields
        },
        effects: [
          {
            "type" => "runtime_containers_validation_recorded",
            "project_id" => project.id,
            "runtime_container_id" => validation.runtime_container.id,
            "validation_status" => validation.runtime_container.validation_status,
            "readiness" => validation.runtime_container.readiness
          }
        ]
      )
    rescue ActiveRecord::RecordNotFound => e
      missing_runtime_container_result(request_id: request_id, message: e.message)
    rescue ArgumentError => e
      invalid_payload_result(request_id: request_id, message: e.message)
    end

    def mark_project_runtime_containers_ready(payload:, context:, request_id:)
      project = find_project(value_from(payload, "project_id"))
      return missing_project_result(request_id: request_id) unless project

      readiness = ReadinessService.new(project: project).call
      unless readiness.ready?
        return CommandQuery::Result.new(
          status: "error",
          request_id: request_id,
          data: {
            "summary" => "Runtime Containers are not ready.",
            "project_id" => project.id,
            "runtime_containers" => readiness.runtime_container.to_state,
            "readiness_problems" => readiness.problems
          },
          effects: [],
          errors: [
            {
              code: "runtime_containers_not_ready",
              message: "Runtime Containers are not ready.",
              details: readiness.problems
            }
          ]
        )
      end

      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "summary" => "Runtime Containers marked ready.",
          "project_id" => project.id,
          "runtime_containers" => readiness.runtime_container.to_state,
          "readiness_problems" => []
        },
        effects: [
          {
            "type" => "runtime_containers_marked_ready",
            "project_id" => project.id,
            "runtime_container_id" => readiness.runtime_container.id
          }
        ]
      )
    rescue ActiveRecord::RecordNotFound => e
      missing_runtime_container_result(request_id: request_id, message: e.message)
    end

    def get_project_runtime_containers(payload:, context:, request_id:)
      project = find_project(value_from(payload, "project_id"))
      return missing_project_result(request_id: request_id) unless project

      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "summary" => "Runtime Containers retrieved.",
          "project_id" => project.id,
          "runtime_containers" => project.runtime_container_state
        },
        effects: []
      )
    end

    private

    def generation_summary(result)
      return "Runtime Containers generated." if result.persisted?

      "Runtime Containers suggestion generated; existing configuration was not overwritten."
    end

    def generation_data(result)
      {
        "persisted" => result.persisted?,
        "generator_source" => result.generator_source,
        "fallback_reason" => result.fallback_reason,
        "errors" => result.errors,
        "input" => result.input
      }
    end

    def missing_project_result(request_id:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "project_not_found",
        message: "project was not found"
      )
    end

    def invalid_record_result(record, request_id:, summary:)
      CommandQuery::Result.new(
        status: "error",
        request_id: request_id,
        data: {"summary" => summary},
        effects: [],
        errors: record.errors.map do |error|
          {
            code: "invalid_#{error.attribute}",
            message: "#{error.attribute} #{error.message}",
            details: {"attribute" => error.attribute.to_s}
          }
        end
      )
    end

    def missing_runtime_container_result(request_id:, message:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "runtime_containers_not_found",
        message: message
      )
    end

    def invalid_payload_result(request_id:, message:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "invalid_payload",
        message: message
      )
    end

    def find_project(project_id)
      return nil if project_id.blank?

      Project.find_by(id: project_id)
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
