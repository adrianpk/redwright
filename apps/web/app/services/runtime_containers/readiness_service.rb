module RuntimeContainers
  class ReadinessService
    Result = Struct.new(:runtime_container, :problems, keyword_init: true) do
      def ready?
        problems.empty?
      end
    end

    def initialize(project:)
      @project = project
    end

    def call
      runtime_container = project.runtime_container
      raise ActiveRecord::RecordNotFound, "Runtime Containers configuration was not found" unless runtime_container

      policy = ReadinessPolicy.new(runtime_container: runtime_container)
      return Result.new(runtime_container: runtime_container, problems: policy.problems) unless policy.ready?

      runtime_container.update!(readiness: "ready", status: "active")
      Result.new(runtime_container: runtime_container.reload, problems: [])
    end

    private

    attr_reader :project
  end
end
