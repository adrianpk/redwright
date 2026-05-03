require "json"

module RuntimeContainers
  class GoCliGenerator
    PROFILE = "go_cli".freeze
    DEFAULT_GO_VERSION = "1.22".freeze
    WORKING_DIRECTORY = "/workspace/project".freeze
    VALIDATION_COMMAND = "go test ./...".freeze

    def self.supported?(input)
      new(input: input).supported?
    end

    def initialize(input:)
      @input = input
    end

    def supported?
      project_type.match?(/\bcli\b/i) &&
        language_runtime.match?(/\bgo\b/i) &&
        framework_supported?
    end

    def attributes
      {
        profile: PROFILE,
        status: "draft",
        readiness: "generated",
        base_image: "golang:#{base_image_version}",
        runtime_name: "go",
        runtime_version: runtime_version,
        working_directory: WORKING_DIRECTORY,
        system_packages: system_packages,
        dependency_commands: dependency_commands,
        test_commands: test_commands,
        lint_commands: lint_commands,
        build_commands: build_commands,
        format_commands: format_commands,
        repository_mount: repository_mount,
        cache_mounts: cache_mounts,
        environment: environment,
        secret_placeholders: secret_placeholders,
        network_policy: network_policy,
        user_policy: user_policy,
        validation_command: VALIDATION_COMMAND,
        validation_status: "not_run",
        validation_output_summary: nil,
        generated_files: generated_files,
        provenance: provenance,
        assumptions: assumptions,
        missing_information: [],
        risks: risks
      }
    end

    private

    attr_reader :input

    def project
      input.fetch("project")
    end

    def stack
      input.fetch("stack")
    end

    def project_type
      stack.fetch("project_type").to_s
    end

    def language_runtime
      stack.fetch("language_runtime").to_s
    end

    def framework
      stack.fetch("framework").to_s.strip.downcase
    end

    def framework_supported?
      framework.empty? || %w[none omitted].include?(framework) || framework == "none specified"
    end

    def runtime_version
      language_runtime.match(/(?:go\s*)?(\d+(?:\.\d+){1,2})/i)&.captures&.first || DEFAULT_GO_VERSION
    end

    def base_image_version
      runtime_version.split(".").first(2).join(".")
    end

    def system_packages
      %w[git ca-certificates]
    end

    def dependency_commands
      [command("download_dependencies", "go mod download", "Download Go modules before validation.")]
    end

    def test_commands
      [command("test", VALIDATION_COMMAND, "Run the project test suite.")]
    end

    def lint_commands
      [command("vet", "go vet ./...", "Run Go static checks.")]
    end

    def build_commands
      [command("build", "go build ./...", "Compile all Go packages.")]
    end

    def format_commands
      [command("format", "gofmt -w .", "Format Go sources in place.")]
    end

    def command(name, shell, purpose)
      {
        "name" => name,
        "command" => shell,
        "working_directory" => WORKING_DIRECTORY,
        "purpose" => purpose
      }
    end

    def repository_mount
      {
        "strategy" => "bind",
        "source" => "repository_root",
        "target" => WORKING_DIRECTORY,
        "read_only" => false
      }
    end

    def cache_mounts
      [
        {"name" => "go-build-cache", "target" => "/root/.cache/go-build", "purpose" => "Go build cache"},
        {"name" => "go-module-cache", "target" => "/go/pkg/mod", "purpose" => "Go module cache"}
      ]
    end

    def environment
      {
        "GOTOOLCHAIN" => "local",
        "CGO_ENABLED" => "0"
      }
    end

    def secret_placeholders
      [
        {
          "name" => "GIT_AUTH_TOKEN",
          "required" => false,
          "purpose" => "Optional private module or repository access."
        }
      ]
    end

    def network_policy
      {
        "mode" => "limited",
        "required_for" => ["go mod download"],
        "notes" => "Dependency download requires registry and source host access."
      }
    end

    def user_policy
      {
        "user" => "root",
        "notes" => "Initial local-development profile uses the base image default user."
      }
    end

    def generated_files
      [
        {
          "path" => "Dockerfile",
          "kind" => "containerfile",
          "content" => dockerfile_body
        },
        {
          "path" => ".redwright/runtime-containers.json",
          "kind" => "metadata",
          "content" => JSON.pretty_generate(runtime_metadata)
        }
      ]
    end

    def dockerfile_body
      <<~DOCKERFILE
        FROM golang:#{base_image_version}

        RUN apt-get update \\
            && apt-get install -y --no-install-recommends git ca-certificates \\
            && rm -rf /var/lib/apt/lists/*

        WORKDIR #{WORKING_DIRECTORY}
        ENV GOTOOLCHAIN=local
        ENV CGO_ENABLED=0

        CMD ["go", "test", "./..."]
      DOCKERFILE
    end

    def runtime_metadata
      {
        "profile" => PROFILE,
        "runtime_name" => "go",
        "runtime_version" => runtime_version,
        "working_directory" => WORKING_DIRECTORY,
        "validation_command" => VALIDATION_COMMAND
      }
    end

    def provenance
      {
        "source" => "deterministic_go_cli_generator",
        "generator_version" => 1,
        "supported_profile" => PROFILE,
        "confidence" => 0.92,
        "input_signals" => input.fetch("signals")
      }
    end

    def assumptions
      [
        "The repository is a Go CLI project or will be initialized as one before validation.",
        "The repository can be bind-mounted at #{WORKING_DIRECTORY} for agent execution.",
        "Go module dependencies can be downloaded during setup or validation."
      ]
    end

    def risks
      [
        {
          "severity" => "low",
          "message" => "The generated container is for local agent development and is not a production deployment artifact."
        },
        {
          "severity" => "low",
          "message" => "The Go base image tag should be checked against the target project version before marking ready."
        }
      ]
    end
  end
end
