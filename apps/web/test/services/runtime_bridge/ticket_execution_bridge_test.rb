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
      ticket = ticket_with_document
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
      assert_equal ticket.id, payload.dig("rails", "ticket_id")
      assert_includes payload.fetch("message"), "Start Rails ticket ##{ticket.id}: #{ticket.title}"
      assert_includes payload.fetch("message"), "reference: Bridge Draft"
    end

    private

    def ticket_with_document
      board = create_board(project_key: "runtime-bridge-#{SecureRandom.hex(4)}")
      backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      draft = create_document(project: board.project, title: "Bridge Draft")
      ticket = board.tickets.create!(
        column: backlog,
        title: "Bridge runtime ticket",
        description: "Run this from Rails.",
        priority: :high,
        assignee: "agent-coder"
      )
      ticket.ticket_document_links.create!(document: draft, role: "reference")
      ticket
    end
  end
end
