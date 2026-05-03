require "test_helper"

module RuntimeContainers
  class ExecutionReadinessTest < ActiveSupport::TestCase
    test "builds execution context for ready runtime containers" do
      project = create_project(key: "runtime-execution-ready")
      runtime_container = create_ready_runtime_container(project)

      result = ExecutionReadiness.new(project: project, runtime_context: {"container_profile" => "ephemeral_docker"}).call

      assert result.ok?, result.problems.inspect
      context = result.context
      assert_equal runtime_container.id, context.fetch("configuration_id")
      assert_equal "ready", context.fetch("readiness")
      assert_equal "passed", context.fetch("validation_status")
      assert_equal "ephemeral_docker", context.fetch("sandbox_strategy")
      assert_equal project.root_path, context.fetch("workspace_root")
      assert_equal "/workspace", context.fetch("sandbox_repository_root")
      assert_equal ["go test ./..."], context.dig("execution_commands", "test")
      assert_equal "go test ./...", context.dig("execution_commands", "validation")
    end

    test "returns missing problem when sandboxed execution has no runtime containers" do
      project = create_project(key: "runtime-execution-missing")

      result = ExecutionReadiness.new(project: project, runtime_context: {"container_profile" => "ephemeral_docker"}).call

      assert_not result.ok?
      assert_equal "runtime_containers_missing", result.problems.first.fetch("code")
      assert_equal "missing", result.context.fetch("readiness")
      assert_includes result.operator_message, "configuration is missing"
    end

    test "returns blocked problem for blocked runtime containers" do
      project = create_project(key: "runtime-execution-blocked")
      create_ready_runtime_container(project).update!(readiness: "blocked")

      result = ExecutionReadiness.new(project: project, runtime_context: {"container_profile" => "ephemeral_docker"}).call

      assert_not result.ok?
      assert_equal "runtime_containers_blocked", result.problems.first.fetch("code")
      assert_equal "blocked", result.problems.first.dig("details", "readiness")
    end

    test "returns not-ready problem before ready transition" do
      project = create_project(key: "runtime-execution-not-ready")
      create_ready_runtime_container(project).update!(readiness: "validated")

      result = ExecutionReadiness.new(project: project, runtime_context: {"container_profile" => "ephemeral_docker"}).call

      assert_not result.ok?
      assert_equal "runtime_containers_not_ready", result.problems.first.fetch("code")
      assert_equal "validated", result.problems.first.dig("details", "readiness")
    end

    test "returns stale validation problem even when readiness still says ready" do
      project = create_project(key: "runtime-execution-stale")
      create_ready_runtime_container(project).update!(validation_status: "stale")

      result = ExecutionReadiness.new(project: project, runtime_context: {"container_profile" => "ephemeral_docker"}).call

      assert_not result.ok?
      assert_equal "runtime_containers_validation_stale", result.problems.first.fetch("code")
      assert_equal "stale", result.problems.first.dig("details", "validation_status")
    end

    test "does not require runtime containers for explicit host execution" do
      project = create_project(key: "runtime-execution-host")

      result = ExecutionReadiness.new(project: project, runtime_context: {"container_profile" => "host"}).call

      assert result.ok?, result.problems.inspect
      assert_not result.sandbox_required
      assert_equal "host", result.context.fetch("sandbox_strategy")
    end

    private

    def create_ready_runtime_container(project)
      project.create_runtime_container!(
        profile: "ephemeral_docker",
        status: "active",
        readiness: "ready",
        base_image: "golang:1.26",
        runtime_name: "go",
        runtime_version: "1.26",
        working_directory: "/workspace",
        repository_mount: {"strategy" => "bind", "target" => "/workspace"},
        test_commands: ["go test ./..."],
        validation_command: "go test ./...",
        validation_status: "passed",
        generated_files: [{"path" => "Dockerfile", "status" => "accepted"}],
        provenance: {"generated_files_decision" => "accepted"}
      )
    end
  end
end
