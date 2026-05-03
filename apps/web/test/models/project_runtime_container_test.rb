require "test_helper"

class ProjectRuntimeContainerTest < ActiveSupport::TestCase
  test "belongs to one project runtime container state" do
    project = create_project(key: "runtime-container-owner")
    runtime_container = project.create_runtime_container!(
      profile: "coder",
      readiness: "generated",
      validation_status: "not_run"
    )

    assert_equal runtime_container, project.reload.runtime_container
    assert_equal project.id, runtime_container.to_state.fetch("project_id")
  end

  test "defaults to explicit non-ready state" do
    runtime_container = create_project(key: "runtime-container-defaults").create_runtime_container!

    assert_equal "default", runtime_container.profile
    assert_equal "draft", runtime_container.status
    assert_equal "missing", runtime_container.readiness
    assert_equal "not_run", runtime_container.validation_status
  end

  test "validates readiness and validation state contracts" do
    runtime_container = create_project(key: "runtime-container-states").build_runtime_container(
      readiness: "unknown",
      validation_status: "unknown"
    )

    assert_not runtime_container.valid?
    assert_includes runtime_container.errors[:readiness], "is not included in the list"
    assert_includes runtime_container.errors[:validation_status], "is not included in the list"
  end

  test "persists structured execution fields and generated files" do
    runtime_container = create_project(key: "runtime-container-structured").create_runtime_container!(
      readiness: "generated",
      runtime_name: "go",
      runtime_version: "1.26.2",
      working_directory: "/workspace/app",
      system_packages: ["git", "ca-certificates"],
      dependency_commands: [{"name" => "download modules", "command" => "go mod download"}],
      test_commands: [{"name" => "test", "command" => "go test ./..."}],
      lint_commands: [{"name" => "vet", "command" => "go vet ./..."}],
      build_commands: [{"name" => "build", "command" => "go build ./..."}],
      format_commands: [{"name" => "format", "command" => "gofmt -w ."}],
      repository_mount: {"strategy" => "bind", "target" => "/workspace/app"},
      cache_mounts: [{"name" => "go-build", "target" => "/root/.cache/go-build"}],
      environment: {"CGO_ENABLED" => "0"},
      secret_placeholders: [{"name" => "GIT_TOKEN", "required" => false}],
      network_policy: {"mode" => "limited"},
      user_policy: {"user" => "agent"},
      validation_command: "go test ./...",
      generated_files: [{"path" => "Dockerfile", "content" => "FROM golang:1.26"}]
    )

    state = runtime_container.reload.to_state
    assert_equal ["git", "ca-certificates"], state.fetch("system_packages")
    assert_equal "go mod download", state.fetch("dependency_commands").first.fetch("command")
    assert_equal "go test ./...", state.fetch("test_commands").first.fetch("command")
    assert_equal "Dockerfile", state.fetch("generated_files").first.fetch("path")
    assert_equal "/workspace/app", state.fetch("repository_mount").fetch("target")
    assert_equal "GIT_TOKEN", state.fetch("secret_placeholders").first.fetch("name")
  end

  test "persists provenance assumptions missing information and risks" do
    runtime_container = create_project(key: "runtime-container-provenance").create_runtime_container!(
      provenance: {
        "source" => "project_setup",
        "input_signals" => [{"key" => "language_runtime", "value" => "Go 1.26.2"}],
        "confidence" => 0.84
      },
      assumptions: ["repository uses Go modules"],
      missing_information: ["preferred base image is unknown"],
      risks: [{"severity" => "medium", "message" => "network access policy needs review"}]
    )

    state = runtime_container.reload.to_state
    assert_equal "project_setup", state.fetch("provenance").fetch("source")
    assert_equal "Go 1.26.2", state.fetch("provenance").fetch("input_signals").first.fetch("value")
    assert_equal ["repository uses Go modules"], state.fetch("assumptions")
    assert_equal ["preferred base image is unknown"], state.fetch("missing_information")
    assert_equal "network access policy needs review", state.fetch("risks").first.fetch("message")
  end

  test "marks validation stale after readiness critical edits" do
    runtime_container = create_project(key: "runtime-container-stale").create_runtime_container!(
      readiness: "validated",
      validation_status: "passed",
      base_image: "golang:1.26",
      validation_command: "go test ./..."
    )

    runtime_container.update!(base_image: "golang:1.26-alpine")

    assert_equal "stale", runtime_container.reload.validation_status
  end

  test "project exposes missing runtime container state without a record" do
    project = create_project(key: "runtime-container-missing")

    state = project.runtime_container_state

    assert_nil state.fetch("id")
    assert_equal project.id, state.fetch("project_id")
    assert_equal "missing", state.fetch("status")
    assert_equal "missing", state.fetch("readiness")
    assert_equal "not_run", state.fetch("validation_status")
    assert_equal [], state.fetch("generated_files")
  end
end
