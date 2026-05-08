require "test_helper"

class AgentTicketExecutionWorkspaceFixtureTest < ActiveSupport::TestCase
  test "creates a resettable Go todo CLI workspace fixture with a local Git repository" do
    with_agent_ticket_execution_workspace do |fixture|
      assert_path_exists fixture.project_path
      assert_equal File.join(fixture.workspace_root, "_workspace", "testing", "Projects"), fixture.projects_root
      assert_equal fixture.project_path, fixture.project.root_path
      assert_equal "local://todo-cli", fixture.project.repo_url

      assert_path_exists File.join(fixture.project_path, ".git")
      assert_equal "true\n", git_output("rev-parse --is-inside-work-tree", fixture.project_path)
      assert_empty git_output("remote", fixture.project_path)

      assert_path_exists File.join(fixture.project_path, ".gitignore")
      assert_path_exists File.join(fixture.project_path, "go.mod")
      assert_path_exists File.join(fixture.project_path, "main.go")
      assert_path_exists File.join(fixture.project_path, "main_test.go")
      assert_includes File.read(File.join(fixture.project_path, "go.mod")), "module example.com/todo"
      assert_includes File.read(File.join(fixture.project_path, "main_test.go")), "tests := []struct"
      assert_includes File.read(File.join(fixture.project_path, "main_test.go")), "done command marks the selected task"

      assert_equal "Implement done command", fixture.ticket.title
      assert_equal "ready", fixture.ticket.workflow_status
      assert_equal fixture.columns.fetch("backlog"), fixture.ticket.column

      File.write(File.join(fixture.project_path, "scratch.txt"), "dirty\n")
      assert_not_empty git_output("status --short", fixture.project_path)

      fixture.reset!
      assert_not File.exist?(File.join(fixture.project_path, "scratch.txt"))
      assert_empty git_output("status --short", fixture.project_path)
    end
  end

  test "tears down the temporary workspace after the fixture block" do
    workspace_path = nil

    with_agent_ticket_execution_workspace do |fixture|
      workspace_path = fixture.workspace_root
      assert_path_exists workspace_path
    end

    assert_not File.exist?(workspace_path)
  end

  private

  def git_output(command, path)
    stdout, stderr, status = Open3.capture3("git #{command}", chdir: path)
    assert status.success?, stderr
    stdout
  end
end
