require "test_helper"

module RuntimeBridge
  class TicketExecutionBridgeTest < ActiveSupport::TestCase
    class FakeRuntimeClient
      attr_reader :requests

      def initialize(payload:)
        @payload = payload
        @requests = []
      end

      def request(type:, session_id:, payload:)
        @requests << {"type" => type, "session_id" => session_id, "payload" => payload}
        {
          "type" => "ack",
          "session_id" => session_id,
          "payload" => @payload
        }
      end
    end

    test "builds runtime send request from rails ticket context" do
      ticket = ticket_for_runtime
      runtime_container = create_ready_runtime_container(ticket.project)
      client = FakeRuntimeClient.new(
        payload: {
          "status" => "ok",
          "project_id" => "runtime-project",
          "workstream_id" => "runtime-workstream",
          "task_id" => "runtime-task",
          "state" => "executing"
        }
      )

      result = TicketExecutionBridge.new(client: client).start(
        ticket: ticket,
        request_id: "req-runtime-start",
        actor_identifier: "api:test"
      )

      assert result.ok?, result.error_message
      assert_equal "started", result.status
      assert_equal "runtime-project", result.runtime_project_ref
      assert_equal "runtime-workstream", result.runtime_workstream_id
      assert_equal "runtime-task", result.runtime_task_id
      request = client.requests.first
      assert_equal "send", request.fetch("type")
      assert_equal "rails-ticket-#{ticket.id}", request.fetch("session_id")
      payload = request.fetch("payload")
      assert_equal "rails", payload.fetch("channel")
      assert_equal ticket.project.root_path, payload.fetch("project_ref")
      assert_equal "Ruby 3.4", payload.dig("runtime_context", "language_runtime")
      assert_equal "Rails", payload.dig("runtime_context", "framework")
      assert_equal "SQLite", payload.dig("runtime_context", "libraries")
      assert_equal "ephemeral_docker", payload.dig("runtime_context", "container_profile")
      assert_equal runtime_container.id, payload.dig("runtime_context", "runtime_containers", "configuration_id")
      assert_equal "ready", payload.dig("runtime_context", "runtime_containers", "readiness")
      assert_equal ["bundle exec rails test"], payload.dig("runtime_context", "runtime_containers", "execution_commands", "test")
      assert_equal "Ruby 3.4", payload.dig("project_setup_context", "slots", "language_runtime", "value")
      assert_equal ticket.id, payload.dig("rails", "ticket_id")
      assert_equal runtime_container.id, payload.dig("rails", "runtime_containers", "configuration_id")
      assert_equal "Rails", payload.dig("rails", "project_setup_context", "slots", "framework", "value")
      assert_includes payload.fetch("message"), "Start Rails ticket ##{ticket.id}: #{ticket.title}"
      assert_includes payload.fetch("message"), "Runtime context: Ruby 3.4 / Rails / ephemeral_docker"
      assert_includes payload.fetch("message"), "Runtime Containers: ##{runtime_container.id} ready / passed"
    end

    test "does not call runtime when runtime containers are missing" do
      ticket = ticket_for_runtime
      client = FakeRuntimeClient.new(payload: {"status" => "ok"})

      result = TicketExecutionBridge.new(client: client).start(
        ticket: ticket,
        request_id: "req-runtime-missing",
        actor_identifier: "api:test"
      )

      assert_not result.ok?
      assert_equal "failed", result.status
      assert_equal "runtime_containers_missing", result.error_code
      assert_empty client.requests
      assert_equal "runtime_containers_missing", result.error_details.dig("readiness_problems", 0, "code")
      assert_equal "missing", result.error_details.dig("runtime_containers", "readiness")
    end

    private

    def ticket_for_runtime
      board = create_board(project_key: "runtime-bridge-#{SecureRandom.hex(4)}")
      board.project.project_attributes.create!(key: "setup_context.language_runtime", value: "Ruby 3.4", weight: 5, source: "project_setup")
      board.project.project_attributes.create!(key: "setup_context.framework", value: "Rails", weight: 5, source: "project_setup")
      board.project.project_attributes.create!(key: "setup_context.libraries", value: "SQLite", weight: 4, source: "project_setup")
      backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      board.tickets.create!(
        column: backlog,
        title: "Bridge runtime ticket",
        description: "Run this from Rails.",
        priority: :high,
        assignee: "agent-coder"
      )
    end

    def create_ready_runtime_container(project)
      project.create_runtime_container!(
        profile: "ephemeral_docker",
        status: "active",
        readiness: "ready",
        base_image: "ruby:3.4",
        runtime_name: "ruby",
        runtime_version: "3.4",
        working_directory: "/workspace",
        repository_mount: {"strategy" => "bind", "target" => "/workspace"},
        test_commands: ["bundle exec rails test"],
        validation_command: "bundle exec rails test",
        validation_status: "passed",
        generated_files: [{"path" => "Dockerfile", "status" => "accepted"}],
        provenance: {"generated_files_decision" => "accepted"}
      )
    end
  end
end
