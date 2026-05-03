require "test_helper"

module RuntimeContainers
  class ManagementTest < ActiveSupport::TestCase
    test "updates runtime containers fields through command api and marks validation stale" do
      project = create_runtime_project(key: "runtime-management-update")
      runtime_container = GenerationService.new(project: project).call.project.runtime_container
      runtime_container.update!(validation_status: "passed", readiness: "validated")

      result = dispatcher.call(
        "kind" => "command",
        "name" => "UpdateProjectRuntimeContainers",
        "payload" => {
          "project_id" => project.id,
          "runtime_containers" => {
            "base_image" => "golang:1.26-alpine",
            "environment" => {"GOTOOLCHAIN" => "local", "CGO_ENABLED" => "1"}
          }
        },
        "execution_context" => {"actor_identifier" => "test:agent"},
        "request_id" => "req-runtime-management-update"
      )

      assert result.ok?
      state = result.data.fetch("runtime_containers")
      assert_equal "golang:1.26-alpine", state.fetch("base_image")
      assert_equal "1", state.fetch("environment").fetch("CGO_ENABLED")
      assert_equal "edited", state.fetch("readiness")
      assert_equal "stale", state.fetch("validation_status")
      assert_includes result.data.fetch("changed_fields"), "base_image"
      assert_includes result.effects.first.fetch("changed_fields"), "environment"
    end

    test "regenerates proposed runtime containers without overwriting active configuration" do
      project = create_runtime_project(key: "runtime-management-regenerate")
      GenerationService.new(project: project).call
      project.runtime_container.update!(base_image: "golang:1.26-alpine")

      result = dispatcher.call(
        "kind" => "command",
        "name" => "RegenerateProjectRuntimeContainers",
        "payload" => {"project_id" => project.id},
        "execution_context" => {"actor_identifier" => "test:agent"},
        "request_id" => "req-runtime-management-regenerate"
      )

      assert result.ok?
      assert_equal "Runtime Containers suggestion regenerated.", result.data.fetch("summary")
      assert_equal "golang:1.26-alpine", result.data.fetch("runtime_containers").fetch("base_image")
      assert_equal "golang:1.26", result.data.fetch("generated_runtime_containers").fetch("base_image")
      assert_equal "golang:1.26-alpine", project.reload.runtime_container.base_image
      comparison = result.data.fetch("comparison")
      assert_equal true, comparison.fetch("changed")
      assert_includes comparison.fetch("changed_fields"), "base_image"
      assert_equal "runtime_containers_generation_suggested", result.effects.first.fetch("type")
    end

    test "records validation pass skipped failed and stale states" do
      project = create_runtime_project(key: "runtime-management-validation")
      GenerationService.new(project: project).call

      passed = record_validation(project: project, status: "passed", summary: "go test ./... passed")
      assert passed.ok?
      assert_equal "passed", project.reload.runtime_container.validation_status
      assert_equal "validated", project.runtime_container.readiness

      skipped = record_validation(project: project, status: "skipped", summary: "operator accepted external validation")
      assert skipped.ok?
      assert_equal "skipped", project.reload.runtime_container.validation_status
      assert_equal "operator accepted external validation", project.runtime_container.validation_output_summary

      failed = record_validation(project: project, status: "failed", summary: "go test ./... failed")
      assert failed.ok?
      assert_equal "failed", project.reload.runtime_container.validation_status
      assert_equal "blocked", project.runtime_container.readiness

      stale = record_validation(project: project, status: "stale", summary: "commands changed after validation")
      assert stale.ok?
      assert_equal "stale", project.reload.runtime_container.validation_status
      assert_equal "blocked", project.runtime_container.readiness
    end

    test "rejects skipped validation without reason" do
      project = create_runtime_project(key: "runtime-management-skip-reason")
      GenerationService.new(project: project).call

      result = record_validation(project: project, status: "skipped", summary: "")

      assert result.error?
      assert_equal "invalid_payload", result.errors.first.fetch(:code)
      assert_equal "validation skipped requires a reason", result.errors.first.fetch(:message)
    end

    test "blocks ready transition when required fields and validation are missing" do
      project = create_project(key: "runtime-management-not-ready")
      project.create_runtime_container!(
        profile: "manual",
        readiness: "generated",
        validation_status: "not_run"
      )

      result = dispatcher.call(
        "kind" => "command",
        "name" => "MarkProjectRuntimeContainersReady",
        "payload" => {"project_id" => project.id},
        "execution_context" => {"actor_identifier" => "test:agent"},
        "request_id" => "req-runtime-management-not-ready"
      )

      assert result.error?
      assert_equal "runtime_containers_not_ready", result.errors.first.fetch(:code)
      problem_codes = result.data.fetch("readiness_problems").map { |problem| problem.fetch("code") }
      assert_includes problem_codes, "missing_required_field"
      assert_includes problem_codes, "missing_test_command"
      assert_includes problem_codes, "validation_not_ready"
      assert_equal "generated", project.reload.runtime_container.readiness
    end

    test "marks runtime containers ready when readiness rules pass" do
      project = create_runtime_project(key: "runtime-management-ready")
      GenerationService.new(project: project).call
      container = project.runtime_container
      container.update!(
        provenance: container.provenance.merge("generated_files_decision" => "accepted"),
        validation_status: "passed",
        validation_output_summary: "go test ./... passed"
      )

      result = dispatcher.call(
        "kind" => "command",
        "name" => "MarkProjectRuntimeContainersReady",
        "payload" => {"project_id" => project.id},
        "execution_context" => {"actor_identifier" => "test:agent"},
        "request_id" => "req-runtime-management-ready"
      )

      assert result.ok?
      state = result.data.fetch("runtime_containers")
      assert_equal "ready", state.fetch("readiness")
      assert_equal "active", state.fetch("status")
      assert_equal [], result.data.fetch("readiness_problems")
      assert_equal "runtime_containers_marked_ready", result.effects.first.fetch("type")
    end

    test "blocking risks prevent ready transition" do
      project = create_runtime_project(key: "runtime-management-blocking-risk")
      GenerationService.new(project: project).call
      container = project.runtime_container
      container.update!(
        provenance: container.provenance.merge("generated_files_decision" => "accepted"),
        validation_status: "passed",
        validation_output_summary: "go test ./... passed",
        risks: [{"severity" => "blocking", "message" => "secret policy unresolved"}]
      )

      result = dispatcher.call(
        "kind" => "command",
        "name" => "MarkProjectRuntimeContainersReady",
        "payload" => {"project_id" => project.id},
        "execution_context" => {"actor_identifier" => "test:agent"},
        "request_id" => "req-runtime-management-blocking-risk"
      )

      assert result.error?
      problem_codes = result.data.fetch("readiness_problems").map { |problem| problem.fetch("code") }
      assert_includes problem_codes, "blocking_risk"
      assert_equal "generated", project.reload.runtime_container.readiness
    end

    private

    def create_runtime_project(key:)
      project = create_project(name: key, key: key)
      write_setup_attribute(project, "project_type", "cli", 5)
      write_setup_attribute(project, "language_runtime", "Go 1.26.2", 5)
      write_setup_attribute(project, "framework", "none", 4)
      write_setup_attribute(project, "libraries", "github.com/urfave/cli/v2", 3)
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

    def record_validation(project:, status:, summary:)
      dispatcher.call(
        "kind" => "command",
        "name" => "RecordProjectRuntimeContainerValidation",
        "payload" => {
          "project_id" => project.id,
          "validation_status" => status,
          "validation_output_summary" => summary
        },
        "execution_context" => {"actor_identifier" => "test:agent"},
        "request_id" => "req-runtime-management-validation-#{status}"
      )
    end

    def dispatcher
      CommandQuery::ApplicationDispatcher.build
    end
  end
end
