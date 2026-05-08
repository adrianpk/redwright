require "test_helper"

module AgentTicketExecution
  class OutputApplierTest < ActiveSupport::TestCase
    test "applies file and command output inside the ticket workspace" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)

        result = OutputApplier.new.apply(
          workspace: workspace,
          payload: {
            "files" => [
              {"path" => "agent-output.txt", "content" => "done\n"}
            ],
            "commands" => [
              {"command" => "test -f agent-output.txt"}
            ]
          }
        )

        assert result.ok?, result.to_h.inspect
        assert_equal ["agent-output.txt"], result.affected_files
        assert_equal %w[write_file run], result.action_results.map(&:type)
        assert_equal "done\n", File.read(File.join(fixture.project_path, "agent-output.txt"))
      end
    end

    test "applies direct primitive actions without adding new primitive types" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)

        result = OutputApplier.new.apply(
          workspace: workspace,
          payload: {
            "actions" => [
              {
                "id" => "write-direct",
                "type" => "write_file",
                "args" => {"path" => "direct.txt", "content" => "direct\n"}
              }
            ],
            "affected_files" => ["direct.txt"]
          }
        )

        assert result.ok?, result.to_h.inspect
        assert_equal ["direct.txt"], result.affected_files
        assert_equal "direct\n", File.read(File.join(fixture.project_path, "direct.txt"))
      end
    end

    test "rejects invalid output before primitive execution" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)

        result = OutputApplier.new.apply(
          workspace: workspace,
          payload: {
            "files" => [
              {"path" => "missing-content.txt"}
            ]
          }
        )

        assert_not result.ok?
        assert_equal "invalid_output", result.code
        assert_equal "file_1_missing_content_or_patch", result.message
        assert_equal [], result.action_results
      end
    end

    test "returns primitive failure results and stops remaining actions" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)

        result = OutputApplier.new.apply(
          workspace: workspace,
          payload: {
            "commands" => [
              {"command" => "exit 17"},
              {"command" => "touch should-not-run.txt"}
            ]
          }
        )

        assert_not result.ok?
        assert_equal "primitive_failed", result.code
        assert_equal 1, result.action_results.length
        assert_equal "run", result.action_results.first.type
        assert_includes result.action_results.first.error_message, "command_failed"
        assert_not File.exist?(File.join(fixture.project_path, "should-not-run.txt"))
      end
    end
  end
end
