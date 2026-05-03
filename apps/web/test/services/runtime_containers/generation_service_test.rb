require "test_helper"

module RuntimeContainers
  class GenerationServiceTest < ActiveSupport::TestCase
    class MalformedLlmClient
      def generate_runtime_container(input:)
        {"profile" => "bad-output"}
      end
    end

    test "builds generation input from project setup context and workspace hints" do
      project = create_runtime_project(
        key: "go-input-builder",
        project_type: "cli",
        language_runtime: "Go 1.26.2",
        framework: "none",
        libraries: "github.com/urfave/cli/v2"
      )
      ProjectSetupSession.create!(
        project: project,
        actor_identifier: "test:agent",
        request_id: "req-generation-input",
        metadata: {
          "workspace" => {
            "materialized" => true,
            "relative_path" => "_workspace/Projects/go-input-builder",
            "runtime_root_path" => "/workspace/projects/go-input-builder",
            "manifest_relative_path" => "_workspace/Projects/go-input-builder/.redwright/manifest.yml",
            "scaffold_profile" => "go_cli",
            "scaffold_files" => ["go.mod", "main.go"]
          }
        }
      )

      input = GenerationInputBuilder.new(project: project).build

      assert_equal project.id, input.dig("project", "id")
      assert_equal "cli", input.dig("stack", "project_type")
      assert_equal "Go 1.26.2", input.dig("stack", "language_runtime")
      assert_equal "github.com/urfave/cli/v2", input.dig("stack", "libraries")
      assert_equal true, input.dig("workspace", "local_repository")
      assert_equal "go_cli", input.dig("workspace", "scaffold_profile")
      assert_includes input.dig("workspace", "scaffold_files"), "go.mod"
      assert input.fetch("signals").any? { |signal| signal.fetch("key") == "setup_context.language_runtime" }
    end

    test "generates and persists deterministic Go CLI runtime containers" do
      project = create_runtime_project(
        key: "go-generation",
        project_type: "cli",
        language_runtime: "Go 1.26.2",
        framework: "none",
        libraries: "github.com/urfave/cli/v2"
      )

      result = GenerationService.new(project: project).call

      assert result.persisted?
      state = project.reload.runtime_container_state
      assert_equal "go_cli", state.fetch("profile")
      assert_equal "generated", state.fetch("readiness")
      assert_equal "not_run", state.fetch("validation_status")
      assert_equal "go", state.fetch("runtime_name")
      assert_equal "1.26.2", state.fetch("runtime_version")
      assert_equal "golang:1.26", state.fetch("base_image")
      assert_equal "go test ./...", state.fetch("validation_command")
      assert_equal "go test ./...", state.fetch("test_commands").first.fetch("command")
      assert_equal "Dockerfile", state.fetch("generated_files").first.fetch("path")
      assert_includes state.fetch("generated_files").first.fetch("content"), "FROM golang:1.26"
      assert_equal "deterministic_go_cli_generator", state.fetch("provenance").fetch("source")
      assert_equal 0.92, state.fetch("provenance").fetch("confidence")
      assert_empty state.fetch("missing_information")
      assert state.fetch("assumptions").any?
      assert state.fetch("risks").any?
    end

    test "command generates Go CLI runtime containers response" do
      project = create_runtime_project(
        key: "go-generation-command",
        project_type: "cli",
        language_runtime: "Go 1.26.2",
        framework: "none"
      )

      result = dispatcher.call(
        "kind" => "command",
        "name" => "GenerateProjectRuntimeContainers",
        "payload" => {"project_id" => project.id},
        "execution_context" => {"actor_identifier" => "test:agent"},
        "request_id" => "req-generate-runtime-containers"
      )

      assert result.ok?
      assert_equal "Runtime Containers generated.", result.data.fetch("summary")
      assert_equal "runtime_containers_generated", result.effects.first.fetch("type")
      assert_equal "generated", result.data.fetch("runtime_containers").fetch("readiness")
      assert_equal "deterministic_go_cli_generator", result.data.fetch("generation").fetch("generator_source")
    end

    test "unsupported context persists blocked runtime containers without false readiness" do
      project = create_runtime_project(
        key: "ruby-api-unsupported",
        project_type: "api_service",
        language_runtime: "Ruby 3.4",
        framework: "Rails"
      )

      result = GenerationService.new(project: project).call

      assert result.persisted?
      state = project.reload.runtime_container_state
      assert_equal "unsupported", state.fetch("profile")
      assert_equal "blocked", state.fetch("readiness")
      assert_equal "not_run", state.fetch("validation_status")
      assert_empty state.fetch("generated_files")
      assert state.fetch("missing_information").any? { |item| item.include?("No deterministic Runtime Containers profile supports") }
      assert state.fetch("missing_information").any? { |item| item.include?("LLM generation was unavailable") }
      assert_equal "unsupported_context_fallback", state.fetch("provenance").fetch("source")
      assert_equal "llm_unavailable", state.fetch("provenance").fetch("fallback_reason")
    end

    test "malformed llm output does not overwrite existing runtime containers" do
      project = create_runtime_project(
        key: "malformed-llm-existing",
        project_type: "api_service",
        language_runtime: "Ruby 3.4",
        framework: "Rails"
      )
      existing = project.create_runtime_container!(
        profile: "manual",
        readiness: "generated",
        validation_status: "not_run",
        base_image: "ruby:3.4",
        generated_files: [{"path" => "Dockerfile", "content" => "FROM ruby:3.4"}]
      )

      result = GenerationService.new(project: project, llm_client: MalformedLlmClient.new).call

      assert_not result.persisted?
      assert_equal "llm_malformed", result.fallback_reason
      assert result.errors.any? { |error| error.include?("missing required field") }
      assert_equal "blocked", result.generated_state.fetch("readiness")
      assert_equal existing.id, project.reload.runtime_container.id
      assert_equal "manual", project.runtime_container.profile
      assert_equal "ruby:3.4", project.runtime_container.base_image
      assert_equal "Dockerfile", project.runtime_container.generated_files.first.fetch("path")
    end

    test "llm contract rejects malformed output and embedded secret values" do
      output = valid_llm_output.merge(
        "secret_placeholders" => [{"name" => "API_TOKEN", "value" => "do-not-store"}]
      )

      result = LlmGenerationContract.new.validate(output)

      assert_not result.valid?
      assert_includes result.errors, "secret_placeholders[0] must not include a secret value"
    end

    private

    def create_runtime_project(key:, project_type:, language_runtime:, framework:, libraries: "")
      project = Project.create!(
        name: key,
        description: "#{key} description",
        root_path: "/workspace/projects/#{key}",
        repo_url: "local://#{key}",
        stack_slug: language_runtime.downcase.gsub(/[^a-z0-9.]+/, "-").gsub(/\A-+|-+\z/, "")
      )
      write_setup_attribute(project, "project_type", project_type, 5)
      write_setup_attribute(project, "language_runtime", language_runtime, 5)
      write_setup_attribute(project, "framework", framework, 4)
      write_setup_attribute(project, "libraries", libraries, 3) unless libraries.empty?
      write_setup_attribute(project, "runtime_container_profile", "ephemeral_docker", 3)
      write_setup_attribute(project, "agent_workflow_mode", "agent_assisted", 3)
      project
    end

    def write_setup_attribute(project, slot, value, weight)
      ProjectAttribute.create!(
        project: project,
        key: "setup_context.#{slot}",
        value: value,
        weight: weight,
        source: "project_setup"
      )
    end

    def dispatcher
      CommandQuery::ApplicationDispatcher.build
    end

    def valid_llm_output
      {
        "profile" => "llm",
        "status" => "draft",
        "readiness" => "generated",
        "base_image" => "ruby:3.4",
        "runtime_name" => "ruby",
        "runtime_version" => "3.4",
        "working_directory" => "/workspace/project",
        "system_packages" => [],
        "dependency_commands" => [],
        "test_commands" => [],
        "lint_commands" => [],
        "build_commands" => [],
        "format_commands" => [],
        "repository_mount" => {"strategy" => "bind"},
        "cache_mounts" => [],
        "environment" => {},
        "secret_placeholders" => [],
        "network_policy" => {},
        "user_policy" => {},
        "validation_command" => "ruby -v",
        "validation_status" => "not_run",
        "validation_output_summary" => nil,
        "generated_files" => [],
        "provenance" => {"source" => "llm"},
        "assumptions" => [],
        "missing_information" => [],
        "risks" => []
      }
    end
  end
end
