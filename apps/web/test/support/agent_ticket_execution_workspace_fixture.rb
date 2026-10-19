require "fileutils"
require "open3"
require "tmpdir"

module AgentTicketExecutionWorkspaceFixture
  Fixture = Struct.new(
    :workspace_root,
    :projects_root,
    :project_path,
    :project,
    :board,
    :columns,
    :ticket,
    keyword_init: true
  ) do
    def reset!
      AgentTicketExecutionWorkspaceFixture.reset_project_fixture!(project_path)
      self
    end
  end

  module_function

  def done_command_patch
    <<~PATCH
      *** Begin Patch
      *** Update File: main.go
      @@
         "os"
      + "strconv"
      @@
      -  case "list":
      +  case "done":
      +    if len(args) != 2 { return 2 }
      +    number, err := strconv.Atoi(args[1])
      +    if err != nil || number < 1 || number > len(tasks) { return 2 }
      +    tasks[number-1].Done = true
      +    if err := saveTasks(todoFilePath(), tasks); err != nil { return 1 }
      +    fmt.Fprintf(stdout, "done: %d\\n", number)
      +    return 0
      +  case "list":
      *** End Patch
    PATCH
  end

  def reset_project_fixture!(project_path)
    FileUtils.rm_rf(project_path)
    FileUtils.mkdir_p(File.dirname(project_path))
    write_go_todo_project(project_path)
    initialize_local_git_repo(project_path)
  end

  def write_go_todo_project(project_path)
    FileUtils.mkdir_p(project_path)
    File.write(File.join(project_path, ".gitignore"), gitignore_content)
    File.write(File.join(project_path, "go.mod"), go_mod_content)
    File.write(File.join(project_path, "main.go"), go_main_content)
    File.write(File.join(project_path, "main_test.go"), go_test_content)
  end

  def initialize_local_git_repo(project_path)
    run_git!("init -q", project_path)
    run_git!("config user.name redwright-test", project_path)
    run_git!("config user.email redwright-test@example.com", project_path)
    run_git!("add -A", project_path)
    run_git!("commit -q -m \"test: initialize todo fixture\"", project_path)
  end

  def run_git!(command, project_path)
    stdout, stderr, status = Open3.capture3("git #{command}", chdir: project_path)
    return stdout if status.success?

    raise "git #{command} failed: #{stderr}"
  end

  def gitignore_content
    <<~GITIGNORE
      todo.txt
      todo.test
      coverage.out
    GITIGNORE
  end

  def go_mod_content
    <<~GOMOD
      module example.com/todo

      go 1.22
    GOMOD
  end

  def go_main_content
    <<~GO
      package main

      import (
        "bufio"
        "fmt"
        "io"
        "os"
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
          fmt.Fprintln(stderr, "usage: todo <add|list> [task]")
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

  def go_test_content
    <<~GO
      package main

      import (
        "bytes"
        "path/filepath"
        "testing"
      )

      func TestDoneCommand(t *testing.T) {
        tests := []struct {
          name       string
          args       []string
          initial    []Task
          wantCode   int
          wantStdout string
          wantDone   []bool
        }{
          {
            name:       "done command marks the selected task",
            args:       []string{"done", "1"},
            initial:    []Task{{Text: "write fixture tests"}},
            wantCode:   0,
            wantStdout: "done: 1\\n",
            wantDone:   []bool{true},
          },
          {
            name:       "done command preserves other tasks",
            args:       []string{"done", "2"},
            initial:    []Task{{Text: "first"}, {Text: "second"}},
            wantCode:   0,
            wantStdout: "done: 2\\n",
            wantDone:   []bool{false, true},
          },
        }

        for _, tt := range tests {
          t.Run(tt.name, func(t *testing.T) {
            path := filepath.Join(t.TempDir(), "todo.txt")
            t.Setenv("TODO_FILE", path)
            if err := saveTasks(path, tt.initial); err != nil {
              t.Fatalf("seed tasks: %v", err)
            }

            var stdout bytes.Buffer
            var stderr bytes.Buffer
            if code := run(tt.args, &stdout, &stderr); code != tt.wantCode {
              t.Fatalf("run returned %d, want %d; stderr=%q", code, tt.wantCode, stderr.String())
            }
            if got := stdout.String(); got != tt.wantStdout {
              t.Fatalf("stdout = %q, want %q", got, tt.wantStdout)
            }

            tasks, err := loadTasks(path)
            if err != nil {
              t.Fatalf("load tasks: %v", err)
            }
            for index, wantDone := range tt.wantDone {
              if tasks[index].Done != wantDone {
                t.Fatalf("task %d done = %v, want %v", index+1, tasks[index].Done, wantDone)
              }
            }
          })
        }
      }
    GO
  end

  def with_agent_ticket_execution_workspace(project_key: "todo-cli")
    Dir.mktmpdir("redwright-agent-ticket-execution-") do |workspace_root|
      projects_root = File.join(workspace_root, "_workspace", "testing", "Projects")
      project_path = File.join(projects_root, project_key)
      reset_project_fixture!(project_path)

      project = Project.create!(
        name: "Todo CLI Fixture",
        description: "Go CLI fixture project for agent ticket execution tests",
        root_path: project_path,
        repo_url: "local://#{project_key}",
        stack_slug: "go"
      )
      create_default_runtime_container(project)
      board = Board.create!(name: "Todo CLI", project_key: project_key, project: project)
      columns = create_agent_ticket_execution_columns(board)
      ticket = Ticket.create!(
        board: board,
        column: columns.fetch("backlog"),
        title: "Implement done command",
        description: ticket_description,
        assignee: "agent-coder",
        kind: "task",
        severity: "low",
        scope: "runtime",
        source: "implementation"
      )

      yield Fixture.new(
        workspace_root: workspace_root,
        projects_root: projects_root,
        project_path: project_path,
        project: project,
        board: board,
        columns: columns,
        ticket: ticket
      )
    end
  end

  def create_agent_ticket_execution_columns(board)
    [
      ["backlog", "Backlog"],
      ["in_progress", "In Progress"],
      ["review", "Review"],
      ["blocked", "Blocked"],
      ["done", "Done"]
    ].each_with_object({}).with_index do |((key, title), columns), index|
      columns[key] = Column.create!(board: board, key: key, title: title, position: index)
    end
  end

  def create_default_runtime_container(project)
    project.create_runtime_container!(
      profile: "go_cli",
      status: "draft",
      readiness: "generated",
      base_image: "golang:1.22",
      runtime_name: "go",
      runtime_version: "1.22",
      working_directory: "/workspace/project",
      system_packages: ["git", "ca-certificates"],
      dependency_commands: [{"name" => "download", "command" => "go mod download"}],
      test_commands: [{"name" => "test", "command" => "go test ./..."}],
      lint_commands: [{"name" => "vet", "command" => "go vet ./..."}],
      build_commands: [{"name" => "build", "command" => "go build ./..."}],
      format_commands: [{"name" => "format", "command" => "gofmt -w ."}],
      repository_mount: {"strategy" => "bind", "source" => "repository_root", "target" => "/workspace/project"},
      cache_mounts: [],
      environment: {"GOTOOLCHAIN" => "local"},
      secret_placeholders: [],
      network_policy: {"mode" => "limited"},
      user_policy: {"user" => "root"},
      validation_command: "go test ./...",
      validation_status: "not_run",
      generated_files: [],
      provenance: {"source" => "test"},
      assumptions: [],
      missing_information: [],
      risks: []
    )
  end

  def ticket_description
    <<~TEXT
      Add a `done <task-number>` command to the todo CLI.

      Acceptance criteria:
      - `todo done 1` marks task 1 as done.
      - Existing open tasks remain unchanged.
      - `go test ./...` passes.
      - Use only the Go standard library.
    TEXT
  end
end
