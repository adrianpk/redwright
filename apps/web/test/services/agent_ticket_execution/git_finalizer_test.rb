require "test_helper"

module AgentTicketExecution
  class GitFinalizerTest < ActiveSupport::TestCase
    test "creates local commit on ticket branch after successful validation" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(
          ticket: fixture.ticket,
          branch_name: "feature/todo-done"
        )
        File.write(File.join(fixture.project_path, "agent-commit.txt"), "committed\n")

        result = GitFinalizer.new.finalize(
          ticket: fixture.ticket,
          request: {"branch_name" => "feature/todo-done"},
          workspace: workspace,
          validation_result: completed_validation
        )

        assert result.ok?, result.to_h.inspect
        assert_equal "feature/todo-done", current_branch(fixture.project_path)
        assert_equal "feat(ticket): Implement done command", last_commit_subject(fixture.project_path)
        assert_match(/\A[a-f0-9]+\z/, result.commit_sha)
      end
    end

    test "rejects RedWright markers in branch names" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)

        result = GitFinalizer.new.finalize(
          ticket: fixture.ticket,
          request: {"branch_name" => "rw/todo-done"},
          workspace: workspace,
          validation_result: completed_validation
        )

        assert_not result.ok?
        assert_equal "invalid_git_finalization", result.code
        assert_equal "branch_name_contains_redwright_marker", result.message
      end
    end

    test "skips commit when validation is not completed" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)

        result = GitFinalizer.new.finalize(
          ticket: fixture.ticket,
          request: {},
          workspace: workspace,
          validation_result: blocked_validation
        )

        assert result.ok?
        assert_equal "validation_not_completed", result.code
        assert_nil result.branch_name
      end
    end

    private

    def completed_validation
      ValidationLoop::Result.new(
        state: "completed",
        attempts: 1,
        validation_results: [{"status" => "ok"}],
        application_results: [],
        terminal_outcome: {"status" => "ready_for_review"}
      )
    end

    def blocked_validation
      ValidationLoop::Result.new(
        state: "blocked",
        attempts: 1,
        validation_results: [{"status" => "error"}],
        application_results: [],
        terminal_outcome: {"status" => "blocked"}
      )
    end

    def current_branch(path)
      AgentTicketExecutionWorkspaceFixture.run_git!("branch --show-current", path).strip
    end

    def last_commit_subject(path)
      AgentTicketExecutionWorkspaceFixture.run_git!("log -1 --pretty=%s", path).strip
    end
  end
end
