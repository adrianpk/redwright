require "test_helper"

module AgentTicketExecution
  class OperationalSetupTest < ActiveSupport::TestCase
    test "materializes agent operational setup from generated runtime container files" do
      with_agent_ticket_execution_workspace do |fixture|
        create_runtime_container(fixture.project, dockerfile_body: "FROM golang:1.22\nCMD [\"go\", \"test\", \"./...\"]\n")

        setup = OperationalSetup.new(project: fixture.project).ensure!(workspace_path: fixture.project_path)

        assert_equal true, setup.fetch("available")
        assert_equal "materialized", setup.fetch("status")
        assert_equal "runtime_container_generated_file", setup.fetch("source")
        assert_equal ".rw", setup.fetch("root_relative_path")
        assert_equal ".rw/agent", setup.fetch("agent_relative_path")
        assert_equal ".rw/agent/Dockerfile", setup.fetch("dockerfile_relative_path")
        assert_equal ["go test ./..."], setup.fetch("validation_commands")
        assert_equal true, setup.fetch("production_dockerfile_separate")
        assert_path_exists File.join(fixture.project_path, ".rw", "agent", "Dockerfile")
        assert_path_exists File.join(fixture.project_path, ".rw", "agent", "runtime-setup.json")
        assert_path_exists File.join(fixture.project_path, ".rw", "agent", "README.md")
        assert_includes File.read(File.join(fixture.project_path, ".rw", "agent", "Dockerfile")), "FROM golang:1.22"

        metadata = JSON.parse(File.read(File.join(fixture.project_path, ".rw", "agent", "runtime-setup.json")))
        assert_equal "agent_ticket_execution", metadata.fetch("purpose")
        assert_equal fixture.project.runtime_container.id, metadata.fetch("runtime_container_id")
        assert_equal ["go test ./..."], metadata.fetch("validation_commands")
      end
    end

    test "accepts provided operational Dockerfile without overwriting it" do
      with_agent_ticket_execution_workspace do |fixture|
        provided_path = File.join(fixture.project_path, ".rw", "agent", "Dockerfile")
        FileUtils.mkdir_p(File.dirname(provided_path))
        File.write(provided_path, "FROM alpine:3.20\n")
        create_runtime_container(fixture.project, dockerfile_body: "FROM golang:1.22\n")

        setup = OperationalSetup.new(project: fixture.project).ensure!(workspace_path: fixture.project_path)

        assert_equal true, setup.fetch("available")
        assert_equal "available", setup.fetch("status")
        assert_equal "project_file", setup.fetch("source")
        assert_equal ["go test ./..."], setup.fetch("validation_commands")
        assert_equal "FROM alpine:3.20\n", File.read(provided_path)
      end
    end

    test "runtime project context exposes operational setup without materializing it" do
      with_agent_ticket_execution_workspace do |fixture|
        context = RuntimeBridge::ProjectContextBuilder.new(project: fixture.project).build

        setup = context.fetch("operational_setup")
        assert_equal false, setup.fetch("available")
        assert_equal "missing", setup.fetch("status")
        assert_equal ".rw/agent/Dockerfile", setup.fetch("dockerfile_relative_path")
        assert_equal ["go test ./..."], setup.fetch("validation_commands")
        assert_not File.exist?(File.join(fixture.project_path, ".rw", "agent"))
      end
    end

    test "prefers metadata validation commands over runtime container commands" do
      with_agent_ticket_execution_workspace do |fixture|
        setup_path = File.join(fixture.project_path, ".rw", "agent")
        FileUtils.mkdir_p(setup_path)
        File.write(File.join(setup_path, "Dockerfile"), "FROM golang:1.22\n")
        File.write(
          File.join(setup_path, "runtime-setup.json"),
          JSON.generate("source" => "project_file", "validation_commands" => ["go test ./...", "go vet ./..."])
        )
        create_runtime_container(fixture.project, dockerfile_body: "FROM golang:1.22\n")

        setup = OperationalSetup.new(project: fixture.project).discover(workspace_path: fixture.project_path)

        assert_equal ["go test ./...", "go vet ./..."], setup.fetch("validation_commands")
      end
    end

    private

    def create_runtime_container(project, dockerfile_body:)
      runtime_container = project.runtime_container || project.build_runtime_container
      runtime_container.update!(
        profile: "go_cli",
        status: "draft",
        readiness: "generated",
        base_image: "golang:1.22",
        runtime_name: "go",
        runtime_version: "1.22",
        working_directory: "/workspace/project",
        system_packages: ["git", "ca-certificates"],
        dependency_commands: [{"name" => "download", "command" => "go mod download"}],
        test_commands: [{"name" => "test", "command" => "go test ./..."}],
        lint_commands: [{"name" => "vet", "command" => "go vet ./..."}],
        build_commands: [{"name" => "build", "command" => "go build ./..."}],
        format_commands: [{"name" => "format", "command" => "gofmt -w ."}],
        repository_mount: {"strategy" => "bind", "source" => "repository_root", "target" => "/workspace/project"},
        cache_mounts: [],
        environment: {"GOTOOLCHAIN" => "local"},
        secret_placeholders: [],
        network_policy: {"mode" => "limited"},
        user_policy: {"user" => "root"},
        validation_command: "go test ./...",
        validation_status: "not_run",
        generated_files: [{"path" => "Dockerfile", "kind" => "containerfile", "content" => dockerfile_body}],
        provenance: {"source" => "test"},
        assumptions: [],
        missing_information: [],
        risks: []
      )
    end
  end
end
