module RuntimeContainers
  class CommandQueryHandlers
    def self.register(dispatcher)
      new.register(dispatcher)
    end

    def register(dispatcher)
      dispatcher.register_command("GenerateProjectRuntimeContainers", method(:generate_project_runtime_containers))
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
