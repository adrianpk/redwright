require "test_helper"

module AgentTicketExecution
  class WorkspaceBoundaryTest < ActiveSupport::TestCase
    test "resolves ticket workspace and prepares bounded primitive executor" do
      with_agent_ticket_execution_workspace do |fixture|
        result = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)

        assert result.ok?
        assert_equal fixture.project_path, result.workspace_path
        assert_equal "agent-ticket-#{fixture.ticket.display_key.parameterize}", result.branch_name
        assert_equal fixture.project_path, result.context.fetch("workspace_path")

        write = result.primitive_executor.execute(
          project_root: fixture.project_path,
          action: {
            "id" => "write",
            "type" => "write_file",
            "args" => {"path" => "agent-note.txt", "content" => "ok"},
            "timeout_ms" => 2_000
          }
        )

        assert_equal "ok", write.status
        assert_equal "ok", File.read(File.join(fixture.project_path, "agent-note.txt"))
      end
    end

    test "rejects harness root mutation through bounded primitive executor" do
      with_agent_ticket_execution_workspace do |fixture|
        result = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)

        denied = result.primitive_executor.execute(
          project_root: fixture.workspace_root,
          action: {
            "id" => "write",
            "type" => "write_file",
            "args" => {"path" => "harness-note.txt", "content" => "blocked"},
            "timeout_ms" => 2_000
          }
        )

        assert_equal "error", denied.status
        assert_includes denied.error_message, "unsafe_project_root"
        assert_not File.exist?(File.join(fixture.workspace_root, "harness-note.txt"))
      end
    end

    test "rejects workspaces outside the allowed projects root" do
      with_agent_ticket_execution_workspace do |fixture|
        result = WorkspaceBoundary.new(allowed_projects_root: File.join(fixture.workspace_root, "_workspace", "other")).resolve(ticket: fixture.ticket)

        assert_not result.ok?
        assert_equal "workspace_outside_allowed_root", result.code
      end
    end

    test "rejects missing project workspace paths" do
      project = create_project(name: "Missing Workspace", key: "missing-workspace")
      board = create_board(project_key: "missing-workspace-board", project: project)
      backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      ticket = board.tickets.create!(column: backlog, title: "Missing workspace")
      project.update!(root_path: File.join(project.root_path, "missing"))

      result = WorkspaceBoundary.new.resolve(ticket: ticket)

      assert_not result.ok?
      assert_equal "workspace_not_found", result.code
    end
  end
end
