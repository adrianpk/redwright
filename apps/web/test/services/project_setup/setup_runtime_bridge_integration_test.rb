require "test_helper"

module ProjectSetup
  class SetupRuntimeBridgeIntegrationTest < ActiveSupport::TestCase
    class FakeRuntimeClient
      attr_reader :requests

      def initialize
        @requests = []
      end

      def request(type:, session_id:, payload:)
        @requests << {"type" => type, "session_id" => session_id, "payload" => payload}
        {
          "type" => "ack",
          "session_id" => session_id,
          "payload" => {
            "status" => "ok",
            "project_id" => payload.fetch("project_ref"),
            "workstream_id" => "setup-workstream",
            "task_id" => "setup-task",
            "state" => "executing"
          }
        }
      end
    end

    test "completed setup starter ticket sends setup context to runtime bridge" do
      session = ProjectSetupSession.create!(
        actor_identifier: "telegram:chat:11:user:77",
        request_id: "req-setup-runtime-#{SecureRandom.hex(4)}",
        source_channel: "telegram"
      )
      session.assign_setup_slot(key: "project_name", value: "bridge-ready", source: "payload")
      session.assign_setup_slot(key: "description", value: "A small service with runtime bridge context.", source: "payload")
      session.assign_setup_slot(key: "project_type", value: "api_service", source: "user_answer")
      session.assign_setup_slot(key: "language_runtime", value: "Ruby 3.4", source: "user_answer")
      session.assign_setup_slot(key: "framework", value: "Rails", source: "user_answer")
      session.metadata = session.metadata.merge("next_prompt_intent" => prompt_intent("libraries"))
      session.save!

      completion = ContextLoopService.new(session: session).advance!(
        answer: "SQLite",
        normalized_fields: {
          "libraries" => "SQLite",
          "agent_workflow_mode" => "agent_assisted",
          "runtime_container_profile" => "ephemeral_docker"
        },
        source_channel: "telegram",
        request_id: "req-setup-runtime-complete"
      )
      assert completion.ok?

      ticket = Ticket.find(completion.data.fetch("starter_ticket_id"))
      runtime_container = create_ready_runtime_container(ticket.project)
      client = FakeRuntimeClient.new
      result = RuntimeBridge::TicketExecutionBridge.new(client: client).start(
        ticket: ticket,
        request_id: "req-setup-runtime-start",
        actor_identifier: "test:integration"
      )

      assert result.ok?, result.error_message
      payload = client.requests.first.fetch("payload")
      assert_equal "Ruby 3.4", payload.dig("runtime_context", "language_runtime")
      assert_equal "Rails", payload.dig("runtime_context", "framework")
      assert_equal "SQLite", payload.dig("runtime_context", "libraries")
      assert_equal "agent_assisted", payload.dig("runtime_context", "agent_workflow_mode")
      assert_equal "ephemeral_docker", payload.dig("runtime_context", "container_profile")
      assert_equal runtime_container.id, payload.dig("runtime_context", "runtime_containers", "configuration_id")
      assert_equal ticket.id, payload.dig("rails", "ticket_id")
      assert_equal completion.session.project_id, payload.dig("rails", "project_id")
    end

    private

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

    def prompt_intent(slot)
      {
        "kind" => "setup_slot_question",
        "slot" => slot,
        "locale" => "auto",
        "llm_required" => true
      }
    end
  end
end
