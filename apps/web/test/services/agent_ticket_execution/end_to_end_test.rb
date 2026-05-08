require "test_helper"

module AgentTicketExecution
  class EndToEndTest < ActiveSupport::TestCase
    test "executes a ticket through context application validation commit and review transition" do
      with_agent_ticket_execution_workspace(project_key: "todo-cli-e2e-success") do |fixture|
        requester = FakeFuzzyRequester.new([proposed_main_payload(done_command_main)])
        dispatcher = dispatcher_for(fixture, requester: requester, max_attempts: 1)

        result = dispatcher.call(command(fixture.ticket, request_id: "req-agent-e2e-success"))

        assert result.ok?, result.errors.inspect
        execution = result.data.fetch("execution")
        assert_equal "completed", execution.fetch("state")
        assert_equal "ready_for_review", execution.dig("terminal_outcome", "status")
        assert_equal "committed", execution.dig("details", "git", "code")
        assert_match(/\A[a-f0-9]+\z/, execution.dig("details", "git", "commit_sha"))
        assert_equal "moved", execution.dig("details", "kanban", "start", "status")
        assert_equal "moved", execution.dig("details", "kanban", "terminal", "status")
        assert_equal "review", execution.dig("details", "kanban", "terminal", "to_column_key")
        assert_equal 1, requester.contexts.length
        assert_includes requester.contexts.first.context_sections.map(&:name), "ticket"
        assert_includes requester.contexts.first.context_sections.map(&:name), "tests"

        fixture.ticket.reload
        assert_equal fixture.columns.fetch("review").id, fixture.ticket.column_id
        assert_equal "reviewing", fixture.ticket.workflow_status
        assert_equal "feature/todo-done", current_branch(fixture.project_path)
        assert_equal "feat(ticket): Implement done command", last_commit_subject(fixture.project_path)
        assert_empty git_remotes(fixture.project_path)
      end
    end

    test "retries after validation failure and completes with local-only git state" do
      with_agent_ticket_execution_workspace(project_key: "todo-cli-e2e-retry") do |fixture|
        requester = FakeFuzzyRequester.new([
          proposed_main_payload(incorrect_done_command_main),
          proposed_main_payload(done_command_main)
        ])
        dispatcher = dispatcher_for(fixture, requester: requester, max_attempts: 2)

        result = dispatcher.call(command(fixture.ticket, request_id: "req-agent-e2e-retry"))

        assert result.ok?, result.errors.inspect
        execution = result.data.fetch("execution")
        assert_equal "completed", execution.fetch("state")
        assert_equal 2, execution.dig("details", "attempts")
        assert_equal 2, requester.contexts.length
        assert_equal "committed", execution.dig("details", "git", "code")
        assert_equal "review", execution.dig("details", "kanban", "terminal", "to_column_key")
        retry_payload = JSON.parse(requester.contexts.last.user_text)
        assert_equal "validation", retry_payload.fetch("validation_feedback").fetch("stage")
        assert_includes retry_payload.fetch("validation_feedback").to_s, "go test ./..."

        fixture.ticket.reload
        assert_equal fixture.columns.fetch("review").id, fixture.ticket.column_id
        assert_empty git_remotes(fixture.project_path)
      end
    end

    test "blocks unresolved tickets after retry exhaustion without creating a feature commit" do
      with_agent_ticket_execution_workspace(project_key: "todo-cli-e2e-blocked") do |fixture|
        requester = FakeFuzzyRequester.new([
          proposed_main_payload(incorrect_done_command_main),
          proposed_main_payload(incorrect_done_command_main)
        ])
        initial_commit = current_commit(fixture.project_path)
        dispatcher = dispatcher_for(fixture, requester: requester, max_attempts: 2)

        result = dispatcher.call(command(fixture.ticket, request_id: "req-agent-e2e-blocked"))

        assert result.ok?, result.errors.inspect
        execution = result.data.fetch("execution")
        assert_equal "blocked", execution.fetch("state")
        assert_equal "blocked", execution.dig("terminal_outcome", "status")
        assert_equal "retry_limit_exhausted", execution.dig("terminal_outcome", "code")
        assert_equal 2, execution.dig("details", "attempts")
        assert_nil execution.dig("details", "git")
        assert_equal "blocked", execution.dig("details", "kanban", "terminal", "to_column_key")

        fixture.ticket.reload
        assert_equal fixture.columns.fetch("blocked").id, fixture.ticket.column_id
        assert_equal "blocked", fixture.ticket.workflow_status
        assert_equal initial_commit, current_commit(fixture.project_path)
        assert_empty git_remotes(fixture.project_path)
      end
    end

    private

    def dispatcher_for(fixture, requester:, max_attempts:)
      loop = ValidationLoop.new(
        context_composer: ContextComposer.new,
        llm_requester: requester,
        max_attempts: max_attempts
      )
      executor = ValidationExecutor.new(
        validation_loop: loop,
        git_finalizer: GitFinalizer.new
      )
      dispatcher = CommandQuery::Dispatcher.new
      CommandQueryHandlers.new(
        executor: executor,
        workspace_boundary: WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root),
        context_composer: ContextComposer.new
      ).register(dispatcher)
      dispatcher
    end

    def command(ticket, request_id:)
      {
        "kind" => "command",
        "name" => "ExecuteAgentTicket",
        "payload" => {
          "ticket_id" => ticket.id,
          "branch_name" => "feature/todo-done"
        },
        "execution_context" => {
          "actor_identifier" => "test:agent",
          "source_channel" => "test"
        },
        "request_id" => request_id
      }
    end

    def proposed_main_payload(content)
      {
        "status" => "proposed_changes",
        "summary" => "Update todo command handling.",
        "files" => [
          {"path" => "main.go", "content" => content}
        ],
        "commands" => [],
        "affected_files" => ["main.go"]
      }
    end

    def incorrect_done_command_main
      done_command_main.sub("tasks[index].Done = true", "// missing assignment")
    end

    def done_command_main
      <<~GO
        package main

        import (
          "bufio"
          "fmt"
          "io"
          "os"
          "strconv"
          "strings"
        )

        type Task struct {
          Text string
          Done bool
        }

        func main() {
          os.Exit(run(os.Args[1:], os.Stdout, os.Stderr))
        }

        func run(args []string, stdout io.Writer, stderr io.Writer) int {
          if len(args) == 0 {
            fmt.Fprintln(stderr, "usage: todo <add|list|done> [task]")
            return 2
          }

          tasks, err := loadTasks(todoFilePath())
          if err != nil {
            fmt.Fprintf(stderr, "load tasks: %v\\n", err)
            return 1
          }

          switch args[0] {
          case "add":
            if len(args) < 2 || strings.TrimSpace(args[1]) == "" {
              fmt.Fprintln(stderr, "usage: todo add <task>")
              return 2
            }
            tasks = append(tasks, Task{Text: strings.TrimSpace(args[1])})
            if err := saveTasks(todoFilePath(), tasks); err != nil {
              fmt.Fprintf(stderr, "save tasks: %v\\n", err)
              return 1
            }
            fmt.Fprintf(stdout, "added: %d\\n", len(tasks))
            return 0
          case "done":
            if len(args) != 2 {
              fmt.Fprintln(stderr, "usage: todo done <task-number>")
              return 2
            }
            number, err := strconv.Atoi(args[1])
            if err != nil || number < 1 || number > len(tasks) {
              fmt.Fprintln(stderr, "invalid task number")
              return 2
            }
            index := number - 1
            tasks[index].Done = true
            if err := saveTasks(todoFilePath(), tasks); err != nil {
              fmt.Fprintf(stderr, "save tasks: %v\\n", err)
              return 1
            }
            fmt.Fprintf(stdout, "done: %d\\n", number)
            return 0
          case "list":
            for index, task := range tasks {
              marker := " "
              if task.Done {
                marker = "x"
              }
              fmt.Fprintf(stdout, "%d. [%s] %s\\n", index+1, marker, task.Text)
            }
            return 0
          default:
            fmt.Fprintf(stderr, "unknown command: %s\\n", args[0])
            return 2
          }
        }

        func todoFilePath() string {
          if path := os.Getenv("TODO_FILE"); path != "" {
            return path
          }
          return "todo.txt"
        }

        func loadTasks(path string) ([]Task, error) {
          file, err := os.Open(path)
          if os.IsNotExist(err) {
            return nil, nil
          }
          if err != nil {
            return nil, err
          }
          defer file.Close()

          var tasks []Task
          scanner := bufio.NewScanner(file)
          for scanner.Scan() {
            parts := strings.SplitN(scanner.Text(), "\\t", 2)
            if len(parts) != 2 {
              continue
            }
            tasks = append(tasks, Task{Done: parts[0] == "done", Text: parts[1]})
          }
          return tasks, scanner.Err()
        }

        func saveTasks(path string, tasks []Task) error {
          file, err := os.Create(path)
          if err != nil {
            return err
          }
          defer file.Close()

          for _, task := range tasks {
            status := "open"
            if task.Done {
              status = "done"
            }
            if _, err := fmt.Fprintf(file, "%s\\t%s\\n", status, task.Text); err != nil {
              return err
            }
          }
          return nil
        }
      GO
    end

    def current_branch(project_path)
      AgentTicketExecutionWorkspaceFixture.run_git!("branch --show-current", project_path).strip
    end

    def current_commit(project_path)
      AgentTicketExecutionWorkspaceFixture.run_git!("rev-parse HEAD", project_path).strip
    end

    def last_commit_subject(project_path)
      AgentTicketExecutionWorkspaceFixture.run_git!("log -1 --pretty=%s", project_path).strip
    end

    def git_remotes(project_path)
      AgentTicketExecutionWorkspaceFixture.run_git!("remote -v", project_path).strip
    end

    class FakeFuzzyRequester
      Result = Struct.new(:payload, :warnings, keyword_init: true) do
        def ok?
          true
        end
      end

      attr_reader :contexts

      def initialize(payloads)
        @payloads = payloads
        @contexts = []
      end

      def call(execution_context:)
        contexts << execution_context
        payload = @payloads.fetch(contexts.length - 1)
        Result.new(payload: payload, warnings: ["fake fuzzy response #{contexts.length}"])
      end
    end
  end
end
