module RuntimeContainers
  class CommandQueryHandlers
    def self.register(dispatcher)
      new.register(dispatcher)
    end

    def register(dispatcher)
      dispatcher.register_query("GetProjectRuntimeContainers", method(:get_project_runtime_containers))
      dispatcher
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
