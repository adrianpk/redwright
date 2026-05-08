require "test_helper"

module AgentTicketExecution
  class CommandQueryHandlersTest < ActiveSupport::TestCase
    test "executes targeted ticket command through application dispatcher" do
      board = create_board(project_key: "agent-command-targeted-#{SecureRandom.hex(4)}")
      backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      ticket = board.tickets.create!(column: backlog, title: "Targeted implementation")

      result = CommandQuery::ApplicationDispatcher.build.call(command("ExecuteAgentTicket", {
        ticket_id: ticket.id
      }, request_id: "req-agent-targeted"))

      assert result.ok?, result.errors.inspect
      execution = result.data.fetch("execution")
      assert_equal "Agent ticket execution accepted.", result.data.fetch("summary")
      assert_equal "targeted", execution.fetch("mode")
      assert_equal "accepted", execution.fetch("state")
      assert_equal ticket.id, execution.fetch("ticket_id")
      assert_equal board.project_id, execution.fetch("project_id")
      assert_equal board.id, execution.fetch("board_id")
      assert_nil execution.fetch("terminal_outcome")
      assert_equal "accepted", execution.dig("acknowledgement", "status")
      assert_equal "agent_ticket_execution_accepted", result.effects.first.fetch("type")
    end

    test "accepts liberal pickup command without Telegram coupling" do
      board = create_board(project_key: "agent-command-pickup-#{SecureRandom.hex(4)}")
      backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      ticket = board.tickets.create!(column: backlog, title: "Picked implementation", assignee: "agent-coder")

      result = CommandQuery::ApplicationDispatcher.build.call(command("ExecuteAgentTicket", {
        mode: "pickup",
        board_id: board.id,
        assignee: "agent-coder",
        loop: true,
        max_tickets: 3
      }, request_id: "req-agent-pickup"))

      assert result.ok?, result.errors.inspect
      execution = result.data.fetch("execution")
      assert_equal "pickup", execution.fetch("mode")
      assert_equal ticket.id, execution.fetch("ticket_id")
      assert_equal board.id, execution.fetch("board_id")
      assert_equal board.project_id, execution.fetch("project_id")
      assert_equal "agent-coder", execution.fetch("assignee")
      assert_equal true, execution.dig("details", "async")
      assert_equal "accepted_boundary", execution.dig("details", "executor")
    end

    test "returns normalized terminal outcome from injected executor" do
      board = create_board(project_key: "agent-command-terminal-#{SecureRandom.hex(4)}")
      backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      board.columns.create!(key: "in_progress", title: "In Progress", position: 1)
      review = board.columns.create!(key: "review", title: "Review", position: 2)
      ticket = board.tickets.create!(column: backlog, title: "Terminal implementation")
      dispatcher = CommandQuery::Dispatcher.new
      CommandQueryHandlers.new(executor: FakeTerminalExecutor.new).register(dispatcher)

      result = dispatcher.call(command("ExecuteAgentTicket", {
        ticket_id: ticket.id
      }, request_id: "req-agent-terminal"))

      assert result.ok?, result.errors.inspect
      execution = result.data.fetch("execution")
      assert_equal "Agent ticket execution completed.", result.data.fetch("summary")
      assert_equal "completed", execution.fetch("state")
      assert_equal "ready_for_review", execution.dig("terminal_outcome", "status")
      assert_equal ticket.id, execution.dig("terminal_outcome", "ticket_id")
      assert_equal "agent_ticket_execution_completed", result.effects.first.fetch("type")
      assert_equal "test:agent", FakeTerminalExecutor.last_request.fetch("actor_identifier")
      assert_equal "moved", execution.dig("details", "kanban", "start", "status")
      assert_equal "moved", execution.dig("details", "kanban", "terminal", "status")
      assert_equal "review", execution.dig("details", "kanban", "terminal", "to_column_key")

      ticket.reload
      assert_equal review.id, ticket.column_id
      assert_equal "reviewing", ticket.workflow_status
      assert ticket.started_at
      assert ticket.sent_to_review_at
      assert ticket.review_started_at
    end

    test "marks unresolved execution blocked through Kanban transition" do
      board = create_board(project_key: "agent-command-blocked-#{SecureRandom.hex(4)}")
      backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      board.columns.create!(key: "in_progress", title: "In Progress", position: 1)
      blocked = board.columns.create!(key: "blocked", title: "Blocked", position: 2)
      ticket = board.tickets.create!(column: backlog, title: "Blocked implementation")
      dispatcher = CommandQuery::Dispatcher.new
      CommandQueryHandlers.new(executor: FakeBlockedExecutor.new).register(dispatcher)

      result = dispatcher.call(command("ExecuteAgentTicket", {
        ticket_id: ticket.id
      }, request_id: "req-agent-blocked"))

      assert result.ok?, result.errors.inspect
      execution = result.data.fetch("execution")
      assert_equal "blocked", execution.fetch("state")
      assert_equal "blocked", execution.dig("terminal_outcome", "status")
      assert_equal "moved", execution.dig("details", "kanban", "start", "status")
      assert_equal "moved", execution.dig("details", "kanban", "terminal", "status")
      assert_equal "blocked", execution.dig("details", "kanban", "terminal", "to_column_key")

      ticket.reload
      assert_equal blocked.id, ticket.column_id
      assert_equal "blocked", ticket.workflow_status
      assert ticket.started_at
    end

    test "skips Kanban transitions when target columns are missing" do
      board = create_board(project_key: "agent-command-kanban-skip-#{SecureRandom.hex(4)}")
      backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      ticket = board.tickets.create!(column: backlog, title: "Terminal implementation without review")
      dispatcher = CommandQuery::Dispatcher.new
      CommandQueryHandlers.new(executor: FakeTerminalExecutor.new).register(dispatcher)

      result = dispatcher.call(command("ExecuteAgentTicket", {
        ticket_id: ticket.id
      }, request_id: "req-agent-kanban-skip"))

      assert result.ok?, result.errors.inspect
      execution = result.data.fetch("execution")
      assert_equal "skipped", execution.dig("details", "kanban", "start", "status")
      assert_equal "target_column_missing", execution.dig("details", "kanban", "start", "reason")
      assert_equal "skipped", execution.dig("details", "kanban", "terminal", "status")
      assert_equal "target_column_missing", execution.dig("details", "kanban", "terminal", "reason")

      ticket.reload
      assert_equal backlog.id, ticket.column_id
      assert_equal "ready", ticket.workflow_status
    end

    test "rejects invalid command payloads" do
      result = CommandQuery::ApplicationDispatcher.build.call(command("ExecuteAgentTicket", {
        mode: "targeted"
      }, request_id: "req-agent-invalid"))

      assert result.error?
      assert_equal "invalid_payload", result.errors.first.fetch(:code)
      assert_equal "ticket_id is required for targeted execution", result.errors.first.fetch(:message)
    end

    test "rejects ineligible targeted tickets" do
      board = create_board(project_key: "agent-command-ineligible-#{SecureRandom.hex(4)}")
      review = board.columns.create!(key: "review", title: "Review", position: 0)
      ticket = board.tickets.create!(column: review, title: "Already in review")

      result = CommandQuery::ApplicationDispatcher.build.call(command("ExecuteAgentTicket", {
        ticket_id: ticket.id
      }, request_id: "req-agent-ineligible"))

      assert result.error?
      assert_equal "ticket_not_development_ready", result.errors.first.fetch(:code)
    end

    test "passes resolved workspace context to injected executor" do
      with_agent_ticket_execution_workspace do |fixture|
        dispatcher = CommandQuery::Dispatcher.new
        CommandQueryHandlers.new(
          executor: FakeTerminalExecutor.new,
          workspace_boundary: WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root)
        ).register(dispatcher)

        result = dispatcher.call(command("ExecuteAgentTicket", {
          ticket_id: fixture.ticket.id,
          branch_name: "feature/todo-done"
        }, request_id: "req-agent-workspace"))

        assert result.ok?, result.errors.inspect
        assert_equal fixture.project_path, result.data.dig("execution", "workspace", "workspace_path")
        assert_equal "feature/todo-done", result.data.dig("execution", "workspace", "branch_name")
        assert_equal fixture.project_path, FakeTerminalExecutor.last_workspace.workspace_path
      end
    end

    test "passes composed execution context to injected executor" do
      with_agent_ticket_execution_workspace do |fixture|
        dispatcher = CommandQuery::Dispatcher.new
        CommandQueryHandlers.new(
          executor: FakeTerminalExecutor.new,
          workspace_boundary: WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root),
          context_composer: ContextComposer.new
        ).register(dispatcher)

        result = dispatcher.call(command("ExecuteAgentTicket", {
          ticket_id: fixture.ticket.id
        }, request_id: "req-agent-context"))

        assert result.ok?, result.errors.inspect
        assert_includes result.data.dig("execution", "context", "section_names"), "ticket"
        assert_includes result.data.dig("execution", "context", "section_names"), "repository_tree"
        assert_includes FakeTerminalExecutor.last_execution_context.llm_request_inputs.fetch(:context_sections).map(&:name), "tests"
      end
    end

    private

    class FakeTerminalExecutor
      class << self
        attr_accessor :last_request
        attr_accessor :last_workspace
        attr_accessor :last_execution_context
      end

      def call(request:, ticket:, workspace: nil, execution_context: nil)
        self.class.last_request = request
        self.class.last_workspace = workspace
        self.class.last_execution_context = execution_context
        {
          "state" => "completed",
          "acknowledgement" => {
            "status" => "accepted",
            "message" => "Agent ticket execution accepted."
          },
          "terminal_outcome" => {
            "status" => "ready_for_review",
            "ticket_id" => ticket.id,
            "validation" => "passed"
          },
          "details" => {
            "commit_sha" => "abc123"
          }
        }
      end
    end

    class FakeBlockedExecutor
      def call(request:, ticket:, workspace: nil, execution_context: nil)
        {
          "state" => "blocked",
          "acknowledgement" => {
            "status" => "blocked",
            "message" => "Agent ticket execution blocked."
          },
          "terminal_outcome" => {
            "status" => "blocked",
            "ticket_id" => ticket.id,
            "code" => "retry_limit_exhausted",
            "reason" => "validation failed"
          },
          "details" => {
            "validation" => "failed"
          }
        }
      end
    end

    def command(name, payload, request_id:)
      {
        "kind" => "command",
        "name" => name,
        "payload" => payload,
        "execution_context" => {"actor_identifier" => "test:agent", "source_channel" => "test"},
        "request_id" => request_id
      }
    end
  end
end
