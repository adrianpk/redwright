module RuntimeContainers
  class ExecutionReadiness
    NON_SANDBOX_PROFILES = %w[none host host_local local disabled].freeze

    Result = Struct.new(
      :ok,
      :sandbox_required,
      :runtime_container,
      :context,
      :problems,
      :operator_message,
      keyword_init: true
    ) do
      def ok?
        ok == true
      end
    end

    def initialize(project:, runtime_context:)
      @project = project
      @runtime_context = runtime_context.is_a?(Hash) ? runtime_context : {}
    end

    def call
      return not_required_result unless sandbox_required?

      runtime_container = project.runtime_container
      return failure_result(problem("runtime_containers_missing", "Runtime Containers configuration is missing")) unless runtime_container

      problems = readiness_problems(runtime_container)
      return failure_result(*problems, runtime_container: runtime_container) if problems.any?

      Result.new(
        ok: true,
        sandbox_required: true,
        runtime_container: runtime_container,
        context: runtime_container_context(runtime_container),
        problems: [],
        operator_message: "Runtime Containers are ready for sandboxed ticket execution."
      )
    end

    private

    attr_reader :project, :runtime_context

    def sandbox_required?
      !NON_SANDBOX_PROFILES.include?(container_profile.downcase)
    end

    def container_profile
      runtime_context.fetch("container_profile", "").to_s.strip.presence || "ephemeral_docker"
    end

    def not_required_result
      Result.new(
        ok: true,
        sandbox_required: false,
        runtime_container: nil,
        context: {
          "required" => false,
          "sandbox_required" => false,
          "sandbox_strategy" => container_profile,
          "workspace_root" => project.root_path,
          "repository_root" => project.root_path
        },
        problems: [],
        operator_message: "Runtime Containers are not required for this ticket execution."
      )
    end

    def readiness_problems(runtime_container)
      return [problem("runtime_containers_blocked", "Runtime Containers are blocked", runtime_container: runtime_container)] if runtime_container.readiness == "blocked"
      return [problem("runtime_containers_validation_stale", "Runtime Containers validation is stale", runtime_container: runtime_container)] if runtime_container.validation_status == "stale"
      return [problem("runtime_containers_not_ready", "Runtime Containers are not marked ready", runtime_container: runtime_container)] unless runtime_container.readiness == "ready"

      policy_problems = ReadinessPolicy.new(runtime_container: runtime_container).problems
      return [] if policy_problems.empty?

      [
        problem(
          "runtime_containers_not_ready",
          "Runtime Containers readiness rules are not satisfied",
          runtime_container: runtime_container,
          policy_problems: policy_problems
        )
      ]
    end

    def failure_result(*problems, runtime_container: nil)
      Result.new(
        ok: false,
        sandbox_required: true,
        runtime_container: runtime_container,
        context: runtime_container ? runtime_container_context(runtime_container) : missing_context,
        problems: problems,
        operator_message: operator_message(problems)
      )
    end

    def missing_context
      {
        "required" => true,
        "sandbox_required" => true,
        "sandbox_strategy" => container_profile,
        "configuration_id" => nil,
        "readiness" => "missing",
        "validation_status" => "not_run",
        "workspace_root" => project.root_path,
        "repository_root" => project.root_path
      }
    end

    def runtime_container_context(runtime_container)
      {
        "required" => true,
        "sandbox_required" => true,
        "sandbox_strategy" => container_profile,
        "configuration_id" => runtime_container.id,
        "readiness" => runtime_container.readiness,
        "validation_status" => runtime_container.validation_status,
        "workspace_root" => project.root_path,
        "repository_root" => project.root_path,
        "sandbox_repository_root" => runtime_container.repository_mount["target"],
        "base_image" => runtime_container.base_image,
        "runtime_name" => runtime_container.runtime_name,
        "runtime_version" => runtime_container.runtime_version,
        "working_directory" => runtime_container.working_directory,
        "repository_mount" => runtime_container.repository_mount,
        "generated_files" => runtime_container.generated_files,
        "execution_commands" => execution_commands(runtime_container)
      }
    end

    def execution_commands(runtime_container)
      {
        "dependency" => runtime_container.dependency_commands,
        "test" => runtime_container.test_commands,
        "lint" => runtime_container.lint_commands,
        "build" => runtime_container.build_commands,
        "format" => runtime_container.format_commands,
        "validation" => runtime_container.validation_command
      }
    end

    def problem(code, message, runtime_container: nil, policy_problems: [])
      details = {
        "project_id" => project.id,
        "sandbox_required" => true,
        "sandbox_strategy" => container_profile
      }
      if runtime_container
        details["runtime_container_id"] = runtime_container.id
        details["readiness"] = runtime_container.readiness
        details["validation_status"] = runtime_container.validation_status
      end
      details["policy_problems"] = policy_problems if policy_problems.any?

      {
        "code" => code,
        "message" => message,
        "details" => details
      }
    end

    def operator_message(problems)
      first_problem = problems.first || {"message" => "Runtime Containers are not ready"}
      "Runtime Containers are not ready for sandboxed ticket execution: #{first_problem.fetch("message")}."
    end
  end
end
