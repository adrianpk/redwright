require "test_helper"
require "tmpdir"

module AgentTicketExecution
  class ValidationLoopTest < ActiveSupport::TestCase
    test "applies LLM output and completes when validation passes" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
        llm = FakeRequester.new([
          proposed_main_payload(done_command_main)
        ])

        result = loop_for(llm).call(request: request_payload(fixture.ticket), ticket: fixture.ticket, workspace: workspace)

        assert result.completed?, result.to_execution.inspect
        assert_equal 1, result.attempts
        assert_equal "ready_for_review", result.terminal_outcome.fetch("status")
        assert_equal "ok", result.validation_results.first.fetch("status")
        assert_equal 1, llm.contexts.length
      end
    end

    test "feeds validation failure into corrective retry request" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
        llm = FakeRequester.new([
          proposed_main_payload(incorrect_done_command_main),
          proposed_main_payload(done_command_main)
        ])

        result = loop_for(llm, max_attempts: 2).call(request: request_payload(fixture.ticket), ticket: fixture.ticket, workspace: workspace)

        assert result.completed?, result.to_execution.inspect
        assert_equal 2, result.attempts
        retry_payload = JSON.parse(llm.contexts.last.user_text)
        assert_equal "validation", retry_payload.fetch("validation_feedback").fetch("stage")
        assert_includes retry_payload.fetch("validation_feedback").to_s, "go test ./..."
      end
    end

    test "blocks when retry limit is exhausted" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
        llm = FakeRequester.new([
          proposed_main_payload(incorrect_done_command_main),
          proposed_main_payload(incorrect_done_command_main)
        ])

        result = loop_for(llm, max_attempts: 2).call(request: request_payload(fixture.ticket), ticket: fixture.ticket, workspace: workspace)

        assert result.blocked?, result.to_execution.inspect
        assert_equal 2, result.attempts
        assert_equal "blocked", result.terminal_outcome.fetch("status")
        assert_equal "retry_limit_exhausted", result.terminal_outcome.fetch("code")
      end
    end

    test "records previous agent LLM interactions for attempts" do
      with_agent_ticket_execution_workspace do |fixture|
        Dir.mktmpdir("redwright-validation-loop-previous-") do |dir|
          store = PreviousInteractionStore.new(root: dir)
          workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
          llm = FakeRequester.new([proposed_main_payload(done_command_main)])

          loop_for(llm, previous_interaction_store: store).call(
            request: request_payload(fixture.ticket),
            ticket: fixture.ticket,
            workspace: workspace
          )

          records = store.recent(ticket: fixture.ticket, request: request_payload(fixture.ticket))
          assert_equal 1, records.length
          assert_equal "applied", records.first.fetch("outcome")
          assert_includes records.first.fetch("context_section_names"), "ticket"
        end
      end
    end

    test "adapts blocked validation result to command executor outcome" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
        llm = FakeRequester.new([proposed_main_payload(incorrect_done_command_main)])
        executor = ValidationExecutor.new(validation_loop: loop_for(llm, max_attempts: 1))

        execution = executor.call(
          request: request_payload(fixture.ticket).merge("request_id" => "req-validation"),
          ticket: fixture.ticket,
          workspace: workspace
        )

        assert_equal "blocked", execution.fetch("state")
        assert_equal "blocked", execution.dig("terminal_outcome", "status")
        assert_equal "blocked", execution.dig("acknowledgement", "status")
        assert_equal fixture.ticket.id, execution.dig("terminal_outcome", "ticket_id")
      end
    end

    test "adds git details to completed command executor outcome" do
      with_agent_ticket_execution_workspace do |fixture|
        workspace = WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(
          ticket: fixture.ticket,
          branch_name: "feature/todo-done"
        )
        llm = FakeRequester.new([proposed_main_payload(done_command_main)])
        executor = ValidationExecutor.new(
          validation_loop: loop_for(llm, max_attempts: 1),
          git_finalizer: GitFinalizer.new
        )

        execution = executor.call(
          request: request_payload(fixture.ticket).merge("request_id" => "req-validation", "branch_name" => "feature/todo-done"),
          ticket: fixture.ticket,
          workspace: workspace
        )

        assert_equal "completed", execution.fetch("state")
        assert_equal "committed", execution.dig("details", "git", "code")
        assert_equal "feature/todo-done", execution.dig("details", "git", "branch_name")
        assert_match(/\A[a-f0-9]+\z/, execution.dig("details", "git", "commit_sha"))
      end
    end

    private

    def loop_for(llm, max_attempts: ValidationLoop::DEFAULT_MAX_ATTEMPTS, previous_interaction_store: nil)
      ValidationLoop.new(
        context_composer: ContextComposer.new(previous_interaction_store: previous_interaction_store),
        llm_requester: llm,
        max_attempts: max_attempts,
        previous_interaction_store: previous_interaction_store
      )
    end

    def request_payload(ticket)
      {
        "mode" => "targeted",
        "ticket_id" => ticket.id,
        "session_id" => "validation-loop-test",
        "agent_id" => "agent-coder",
        "branch_name" => "agent-ticket-#{ticket.id}",
        "source_channel" => "test",
        "actor_identifier" => "agent-test"
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

    class FakeRequester
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
        Result.new(payload: payload, warnings: [])
      end
    end
  end
end
