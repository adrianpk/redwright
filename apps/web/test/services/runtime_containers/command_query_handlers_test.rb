require "test_helper"

module RuntimeContainers
  class CommandQueryHandlersTest < ActiveSupport::TestCase
    test "queries missing runtime containers state for project" do
      project = create_project(key: "runtime-containers-query-missing")

      result = dispatcher.call(
        "kind" => "query",
        "name" => "GetProjectRuntimeContainers",
        "payload" => {"project_id" => project.id},
        "execution_context" => {"actor_identifier" => "test:agent"},
        "request_id" => "req-runtime-containers-missing"
      )

      assert result.ok?
      state = result.data.fetch("runtime_containers")
      assert_equal "Runtime Containers retrieved.", result.data.fetch("summary")
      assert_equal project.id, result.data.fetch("project_id")
      assert_equal "missing", state.fetch("readiness")
      assert_equal "not_run", state.fetch("validation_status")
    end

    test "queries persisted runtime containers state" do
      project = create_project(key: "runtime-containers-query-existing")
      project.create_runtime_container!(
        readiness: "generated",
        validation_status: "not_run",
        runtime_name: "go",
        runtime_version: "1.26.2",
        test_commands: [{"name" => "test", "command" => "go test ./..."}],
        generated_files: [{"path" => "Dockerfile", "content" => "FROM golang:1.26"}],
        assumptions: ["Go module will be present before validation"]
      )

      result = dispatcher.call(
        "kind" => "query",
        "name" => "GetProjectRuntimeContainers",
        "payload" => {"project_id" => project.id},
        "execution_context" => {"actor_identifier" => "test:agent"},
        "request_id" => "req-runtime-containers-existing"
      )

      assert result.ok?
      state = result.data.fetch("runtime_containers")
      assert_equal "generated", state.fetch("readiness")
      assert_equal "go", state.fetch("runtime_name")
      assert_equal "go test ./...", state.fetch("test_commands").first.fetch("command")
      assert_equal "Dockerfile", state.fetch("generated_files").first.fetch("path")
      assert_equal ["Go module will be present before validation"], state.fetch("assumptions")
    end

    test "project query includes runtime containers state" do
      project = create_project(key: "runtime-containers-project-query")
      project.create_runtime_container!(
        readiness: "generated",
        validation_status: "not_run",
        generated_files: [{"path" => "Containerfile", "content" => "FROM ruby:3.4"}]
      )

      result = dispatcher.call(
        "kind" => "query",
        "name" => "GetProject",
        "payload" => {"project_id" => project.id},
        "execution_context" => {"actor_identifier" => "test:agent"},
        "request_id" => "req-project-runtime-containers"
      )

      assert result.ok?
      runtime_state = result.data.fetch("project").fetch("runtime_containers")
      assert_equal "generated", runtime_state.fetch("readiness")
      assert_equal "Containerfile", runtime_state.fetch("generated_files").first.fetch("path")
    end

    private

    def dispatcher
      CommandQuery::ApplicationDispatcher.build
    end
  end
end
