require "test_helper"

module BoardWorkflow
  class CommandQueryHandlersTest < ActiveSupport::TestCase
    test "creates moves picks and snapshots tickets through dispatcher" do
      board = create_board(project_key: "board-api-#{SecureRandom.hex(4)}")
      backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      review = board.columns.create!(key: "review", title: "Review", position: 1)
      draft = create_document(project: board.project, artifact_type: "draft", title: "Reference Draft", body: "draft")
      spec = create_document(project: board.project, artifact_type: "spec", title: "Primary Spec", body: "spec", source_draft: draft, editable: false)
      use_case = create_use_case(project: board.project, name: "Billing")
      dispatcher = CommandQuery::ApplicationDispatcher.build

      created = dispatcher.call(command("CreateTicket", {
        board_id: board.id,
        column_id: backlog.id,
        title: "Implement command API",
        description: "Expose board workflow",
        priority: "high",
        kind: "task",
        severity: "medium",
        scope: "web",
        source: "implementation",
        owner: "agent-coder",
        branch: "fix/ticket-123",
        pr: "https://codeberg.org/acme/redwright/pulls/123",
        commits: [ "abc123" ],
        assignee: "agent-coder",
        use_case_id: use_case.id,
        document_ids: [ draft.id, spec.id ]
      }, request_id: "req-ticket-create"))

      assert created.ok?, created.errors.inspect
      ticket = Ticket.find(created.data.fetch("ticket_id"))
      assert_equal "high", ticket.priority
      assert_equal "ready", ticket.workflow_status
      assert_equal "task", ticket.kind
      assert_equal "medium", ticket.severity
      assert_equal "web", ticket.scope
      assert_equal "implementation", ticket.source
      assert_equal "agent-coder", ticket.owner
      assert_equal "fix/ticket-123", ticket.branch
      assert_equal "https://codeberg.org/acme/redwright/pulls/123", ticket.pr
      assert_equal [ "abc123" ], ticket.commits
      assert_equal use_case.id, ticket.use_case_id
      assert_equal use_case.id, created.data.fetch("ticket").fetch("use_case_id")
      assert_equal "Billing", created.data.fetch("ticket").fetch("use_case_name")
      assert_equal [ draft.id, spec.id ].sort, ticket.document_ids.sort
      assert_equal "reference", ticket.ticket_document_links.find_by(document_id: draft.id).role
      assert_equal "primary_spec", ticket.ticket_document_links.find_by(document_id: spec.id).role

      moved = dispatcher.call(command("MoveTicket", {
        ticket_id: ticket.id,
        column_key: "review"
      }, request_id: "req-ticket-move"))

      assert moved.ok?, moved.errors.inspect
      assert_equal review.id, ticket.reload.column_id
      assert_equal "reviewing", ticket.workflow_status
      assert_not_nil ticket.review_started_at
      assert_equal "ticket_moved", moved.effects.first.fetch("type")

      picked = dispatcher.call(query("PickNextTicket", {
        board_id: board.id,
        assignee: "agent-coder"
      }, request_id: "req-ticket-pick"))

      assert picked.ok?, picked.errors.inspect
      assert_equal ticket.id, picked.data.fetch("ticket_id")

      snapshot = dispatcher.call(query("GetBoard", {
        board_id: board.id
      }, request_id: "req-board-snapshot"))

      assert snapshot.ok?, snapshot.errors.inspect
      review_column = snapshot.data.dig("board", "columns").find { |column| column.fetch("key") == "review" }
      assert_equal [ ticket.id ], review_column.fetch("tickets").map { |item| item.fetch("id") }
      assert_equal "reviewing", review_column.fetch("tickets").first.fetch("workflow_status")
      assert_equal use_case.id, review_column.fetch("tickets").first.fetch("use_case_id")
      assert_equal [ "abc123" ], review_column.fetch("tickets").first.fetch("commits")
      assert_equal [ draft.id, spec.id ].sort, review_column.fetch("tickets").first.fetch("document_links").map { |item| item.fetch("document_id") }.sort
    end

    test "updates and attaches ticket documents while enforcing project consistency" do
      board = create_board(project_key: "board-api-attach-#{SecureRandom.hex(4)}")
      backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      ticket = board.tickets.create!(column: backlog, title: "Attach target")
      draft = create_document(project: board.project, artifact_type: "draft", title: "Draft")
      foreign = create_document(project: create_project(key: "foreign-doc-#{SecureRandom.hex(4)}"), artifact_type: "draft", title: "Foreign")
      dispatcher = CommandQuery::ApplicationDispatcher.build

      attached = dispatcher.call(command("AttachDocumentToTicket", {
        ticket_id: ticket.id,
        document_id: draft.id
      }, request_id: "req-ticket-attach"))

      assert attached.ok?, attached.errors.inspect
      assert_equal [draft.id], ticket.reload.document_ids

      updated = dispatcher.call(command("UpdateTicket", {
        ticket_id: ticket.id,
        title: "Attach target updated",
        document_ids: []
      }, request_id: "req-ticket-update"))

      assert updated.ok?, updated.errors.inspect
      assert_equal "Attach target updated", ticket.reload.title
      assert_empty ticket.document_ids

      rejected = dispatcher.call(command("AttachDocumentToTicket", {
        ticket_id: ticket.id,
        document_id: foreign.id
      }, request_id: "req-ticket-foreign-doc"))

      assert rejected.error?
      assert_equal "invalid_document", rejected.errors.first.fetch(:code)
      assert_empty ticket.reload.document_ids
    end

    test "adds ticket comments through command query boundary" do
      board = create_board(project_key: "board-api-comments-#{SecureRandom.hex(4)}")
      backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      ticket = board.tickets.create!(column: backlog, title: "Comment target")
      dispatcher = CommandQuery::ApplicationDispatcher.build

      result = dispatcher.call(command("AddTicketComment", {
        ticket_id: ticket.id,
        body: "Blocked on @agent-reviewer.",
        author_type: "agent",
        author_label: "agent-coder",
        author_handle: "agent-coder"
      }, request_id: "req-ticket-comment"))

      assert result.ok?, result.errors.inspect
      comment = ticket.ticket_comments.last
      assert_equal "Blocked on @agent-reviewer.", comment.body
      assert_equal "agent", comment.author_type
      assert_equal "agent-coder", comment.author_label
      assert_equal "ticket_comment_added", result.effects.first.fetch("type")
      assert_equal comment.id, result.data.fetch("comment").fetch("id")
      assert_equal [ "agent-reviewer" ], result.data.fetch("comment").fetch("mentions").map { |mention| mention.fetch("handle") }
      assert_equal comment.id, result.data.fetch("ticket").fetch("comments").first.fetch("id")
    end

    test "lists visible project tickets" do
      board = create_board(project_key: "board-api-project-tickets-#{SecureRandom.hex(4)}")
      backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      done = board.columns.create!(key: "done", title: "Done", position: 1)
      visible = board.tickets.create!(column: backlog, title: "Visible ticket", priority: :high)
      archived = board.tickets.create!(column: done, title: "Archived ticket")
      archived.archive!

      result = CommandQuery::ApplicationDispatcher.build.call(query("GetTicketsByProject", {
        project_id: board.project_id
      }, request_id: "req-project-tickets"))

      assert result.ok?, result.errors.inspect
      assert_equal [visible.id], result.data.fetch("tickets").map { |item| item.fetch("id") }
    end

    test "starts ticket execution and persists runtime correlation" do
      board = create_board(project_key: "board-api-execution-#{SecureRandom.hex(4)}")
      backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      ticket = board.tickets.create!(column: backlog, title: "Executable ticket")
      bridge = FakeTicketExecutionBridge.new
      dispatcher = CommandQuery::Dispatcher.new
      CommandQueryHandlers.new(ticket_execution_bridge: bridge).register(dispatcher)

      result = dispatcher.call(command("StartTicketExecution", {
        ticket_id: ticket.id
      }, request_id: "req-start-execution"))

      assert result.ok?, result.errors.inspect
      ticket.reload
      assert_equal "started", ticket.runtime_execution_status
      assert_equal "runtime-exec-1", ticket.runtime_execution_id
      assert_equal "runtime-workstream-1", ticket.runtime_workstream_id
      assert_equal "runtime-task-1", ticket.runtime_task_id
      assert_equal "executing", ticket.runtime_state
      assert_equal "ticket_execution_started", result.effects.first.fetch("type")
      assert_equal "test:board", bridge.actor_identifier
    end

    test "returns structured readiness details when ticket execution is gated" do
      board = create_board(project_key: "board-api-execution-gated-#{SecureRandom.hex(4)}")
      backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      ticket = board.tickets.create!(column: backlog, title: "Gated ticket")
      client = FakeRuntimeClient.new
      dispatcher = CommandQuery::Dispatcher.new
      CommandQueryHandlers.new(
        ticket_execution_bridge: RuntimeBridge::TicketExecutionBridge.new(client: client)
      ).register(dispatcher)

      result = dispatcher.call(command("StartTicketExecution", {
        ticket_id: ticket.id
      }, request_id: "req-start-gated-execution"))

      assert result.error?
      assert_equal "runtime_containers_missing", result.errors.first.fetch(:code)
      assert_equal "ticket_execution_failed", result.effects.first.fetch("type")
      assert_empty client.requests
      ticket.reload
      assert_equal "failed", ticket.runtime_execution_status
      assert_includes ticket.runtime_execution_error, "Runtime Containers are not ready"
      details = result.errors.first.fetch(:details)
      assert_equal ticket.id, details.fetch("ticket_id")
      assert_equal "missing", details.dig("runtime_containers", "readiness")
      assert_equal "runtime_containers_missing", details.dig("readiness_problems", 0, "code")
    end

    private

    class FakeRuntimeClient
      attr_reader :requests

      def initialize
        @requests = []
      end

      def request(type:, session_id:, payload:)
        @requests << {"type" => type, "session_id" => session_id, "payload" => payload}
        {"type" => "ack", "session_id" => session_id, "payload" => {"status" => "ok"}}
      end
    end

    class FakeTicketExecutionBridge
      attr_reader :actor_identifier

      def start(ticket:, request_id:, actor_identifier:)
        @actor_identifier = actor_identifier
        RuntimeBridge::TicketExecutionBridge::Result.new(
          ok: true,
          status: "started",
          execution_id: "runtime-exec-1",
          runtime_project_ref: ticket.project.root_path,
          runtime_workstream_id: "runtime-workstream-1",
          runtime_task_id: "runtime-task-1",
          runtime_state: "executing",
          runtime_response: {"status" => "ok"},
          error_code: nil,
          error_message: nil
        )
      end
    end

    def command(name, payload, request_id:)
      envelope("command", name, payload, request_id: request_id)
    end

    def query(name, payload, request_id:)
      envelope("query", name, payload, request_id: request_id)
    end

    def envelope(kind, name, payload, request_id:)
      {
        "kind" => kind,
        "name" => name,
        "payload" => payload,
        "execution_context" => {"actor_identifier" => "test:board", "source_channel" => "test"},
        "request_id" => request_id
      }
    end
  end
end
