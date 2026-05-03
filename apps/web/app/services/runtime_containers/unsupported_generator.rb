module RuntimeContainers
  class UnsupportedGenerator
    PROFILE = "unsupported".freeze

    def initialize(input:, fallback_reason:, llm_errors: [])
      @input = input
      @fallback_reason = fallback_reason.to_s
      @llm_errors = Array(llm_errors).map(&:to_s)
    end

    def attributes
      {
        profile: PROFILE,
        status: "draft",
        readiness: "blocked",
        base_image: nil,
        runtime_name: runtime_name,
        runtime_version: runtime_version,
        working_directory: nil,
        system_packages: [],
        dependency_commands: [],
        test_commands: [],
        lint_commands: [],
        build_commands: [],
        format_commands: [],
        repository_mount: {},
        cache_mounts: [],
        environment: {},
        secret_placeholders: [],
        network_policy: {},
        user_policy: {},
        validation_command: nil,
        validation_status: "not_run",
        validation_output_summary: nil,
        generated_files: [],
        provenance: provenance,
        assumptions: assumptions,
        missing_information: missing_information,
        risks: risks
      }
    end

    private

    attr_reader :input, :fallback_reason, :llm_errors

    def stack
      input.fetch("stack")
    end

    def runtime_name
      runtime = stack.fetch("language_runtime").to_s.strip
      runtime.empty? ? nil : runtime.split.first.to_s.downcase
    end

    def runtime_version
      stack.fetch("language_runtime").to_s.match(/(\d+(?:\.\d+){1,2})/)&.captures&.first
    end

    def provenance
      {
        "source" => "unsupported_context_fallback",
        "generator_version" => 1,
        "confidence" => 0.1,
        "fallback_reason" => fallback_reason,
        "llm_errors" => llm_errors,
        "input_signals" => input.fetch("signals")
      }
    end

    def assumptions
      [
        "Manual Runtime Containers configuration is required before sandboxed ticket execution can start."
      ]
    end

    def missing_information
      [
        "No deterministic Runtime Containers profile supports project_type=#{stack.fetch("project_type").inspect}, language_runtime=#{stack.fetch("language_runtime").inspect}, framework=#{stack.fetch("framework").inspect}.",
        "A supported base image, dependency commands, validation command, mount policy, and generated file proposal must be provided."
      ] + llm_missing_information
    end

    def llm_missing_information
      return ["LLM generation was unavailable."] if fallback_reason == "llm_unavailable"
      return ["LLM generation returned malformed structured output."] if fallback_reason == "llm_malformed"

      []
    end

    def risks
      [
        {
          "severity" => "medium",
          "message" => "Sandbox-required ticket execution must remain blocked until Runtime Containers are configured."
        },
        {
          "severity" => "medium",
          "message" => "Unsupported contexts must not be marked ready without manual review and validation."
        }
      ]
    end
  end
end
