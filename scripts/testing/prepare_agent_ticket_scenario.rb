# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "shellwords"

REPO_ROOT = Rails.root.join("..", "..").expand_path
TESTING_ROOT = REPO_ROOT.join("_workspace", "testing")
REFERENCE_ROOT = TESTING_ROOT.join("reference", "go-todo-agent")
PROJECTS_ROOT = TESTING_ROOT.join("Projects")
PROJECT_ROOT = PROJECTS_ROOT.join("go-todo-agent")
PROJECT_NAME = "Go Todo Agent"
PROJECT_KEY = "go-todo-agent"
TICKET_TITLE = "Implement done command"

def execute_sql(statement)
  ActiveRecord::Base.connection.execute(statement)
end

def reset_development_database!
  load Rails.root.join("db", "seeds.rb")

  statements = [
    "PRAGMA foreign_keys = OFF",
    "CREATE TEMP TABLE keep_projects AS SELECT id FROM projects WHERE name = 'Factory'",
    "CREATE TEMP TABLE remove_projects AS SELECT id FROM projects WHERE id NOT IN (SELECT id FROM keep_projects)",
    "CREATE TEMP TABLE remove_boards AS SELECT id FROM boards WHERE project_id IN (SELECT id FROM remove_projects)",
    "CREATE TEMP TABLE remove_columns AS SELECT id FROM columns WHERE board_id IN (SELECT id FROM remove_boards)",
    "CREATE TEMP TABLE remove_tickets AS SELECT id FROM tickets WHERE board_id IN (SELECT id FROM remove_boards)",
    "CREATE TEMP TABLE remove_ticket_comments AS SELECT id FROM ticket_comments WHERE ticket_id IN (SELECT id FROM remove_tickets)",
    "CREATE TEMP TABLE remove_documents AS SELECT id FROM documents WHERE project_id IN (SELECT id FROM remove_projects)",
    "CREATE TEMP TABLE remove_use_cases AS SELECT id FROM use_cases WHERE project_id IN (SELECT id FROM remove_projects)",
    "CREATE TEMP TABLE remove_quizzes AS SELECT id FROM quizzes WHERE project_id IN (SELECT id FROM remove_projects)",
    "CREATE TEMP TABLE remove_protocols AS SELECT id FROM project_protocols WHERE project_id IN (SELECT id FROM remove_projects)",
    "CREATE TEMP TABLE remove_setup_sessions AS SELECT id FROM project_setup_sessions WHERE project_id IN (SELECT id FROM remove_projects)",
    "DELETE FROM ticket_comment_mentions WHERE ticket_id IN (SELECT id FROM remove_tickets) OR ticket_comment_id IN (SELECT id FROM remove_ticket_comments)",
    "DELETE FROM ticket_comments WHERE id IN (SELECT id FROM remove_ticket_comments)",
    "DELETE FROM ticket_labels WHERE ticket_id IN (SELECT id FROM remove_tickets) OR label_id IN (SELECT id FROM labels WHERE board_id IN (SELECT id FROM remove_boards))",
    "DELETE FROM tickets WHERE id IN (SELECT id FROM remove_tickets)",
    "DELETE FROM labels WHERE board_id IN (SELECT id FROM remove_boards)",
    "DELETE FROM columns WHERE id IN (SELECT id FROM remove_columns)",
    "DELETE FROM boards WHERE id IN (SELECT id FROM remove_boards)",
    "DELETE FROM document_relations WHERE from_artifact_id IN (SELECT id FROM remove_documents) OR to_artifact_id IN (SELECT id FROM remove_documents)",
    "DELETE FROM documents WHERE id IN (SELECT id FROM remove_documents)",
    "DELETE FROM project_setup_turns WHERE project_setup_session_id IN (SELECT id FROM remove_setup_sessions)",
    "DELETE FROM project_setup_sessions WHERE id IN (SELECT id FROM remove_setup_sessions)",
    "DELETE FROM quiz_entries WHERE project_id IN (SELECT id FROM remove_projects) OR quiz_id IN (SELECT id FROM remove_quizzes) OR use_case_id IN (SELECT id FROM remove_use_cases)",
    "DELETE FROM quizzes WHERE id IN (SELECT id FROM remove_quizzes)",
    "DELETE FROM taggings WHERE project_id IN (SELECT id FROM remove_projects) OR use_case_id IN (SELECT id FROM remove_use_cases)",
    "DELETE FROM use_cases WHERE id IN (SELECT id FROM remove_use_cases)",
    "DELETE FROM project_protocol_documents WHERE project_protocol_id IN (SELECT id FROM remove_protocols)",
    "DELETE FROM project_protocols WHERE id IN (SELECT id FROM remove_protocols)",
    "DELETE FROM project_runtime_containers WHERE project_id IN (SELECT id FROM remove_projects)",
    "DELETE FROM project_attributes WHERE project_id IN (SELECT id FROM remove_projects)",
    "DELETE FROM projects WHERE id IN (SELECT id FROM remove_projects)",
    "DROP TABLE keep_projects",
    "DROP TABLE remove_projects",
    "DROP TABLE remove_boards",
    "DROP TABLE remove_columns",
    "DROP TABLE remove_tickets",
    "DROP TABLE remove_ticket_comments",
    "DROP TABLE remove_documents",
    "DROP TABLE remove_use_cases",
    "DROP TABLE remove_quizzes",
    "DROP TABLE remove_protocols",
    "DROP TABLE remove_setup_sessions",
    "PRAGMA foreign_keys = ON"
  ]

  ActiveRecord::Base.transaction do
    statements.each { |statement| execute_sql(statement) }
  end
end

def write_file(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content)
end

def run_command!(command, chdir:)
  _stdout, stderr, status = Open3.capture3(command, chdir: chdir)
  return if status.success?

  raise "#{command} failed: #{stderr}"
end

def go_todo_main
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

def go_todo_test
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

def initialize_reference_workspace!
  FileUtils.rm_rf(REFERENCE_ROOT)
  FileUtils.mkdir_p(REFERENCE_ROOT)
  write_file(REFERENCE_ROOT.join(".gitignore"), "todo.txt\ntodo.test\ncoverage.out\n")
  write_file(REFERENCE_ROOT.join("go.mod"), "module example.com/todo\n\ngo 1.22\n")
  write_file(REFERENCE_ROOT.join("main.go"), go_todo_main)
  write_file(REFERENCE_ROOT.join("main_test.go"), go_todo_test)
  write_file(
    REFERENCE_ROOT.join(".rw", "agent", "Dockerfile"),
    <<~DOCKERFILE
      FROM golang:1.22-alpine
      WORKDIR /workspace
      COPY . .
      RUN go test ./...
    DOCKERFILE
  )
  write_file(
    REFERENCE_ROOT.join(".rw", "agent", "runtime-setup.json"),
    JSON.pretty_generate(
      "purpose" => "agent_ticket_execution",
      "validation_commands" => ["go test ./..."],
      "runtime" => {"name" => "go", "version" => "1.22"}
    )
  )

  run_command!("git init -q", chdir: REFERENCE_ROOT.to_s)
  run_command!("git config user.name redwright-testing", chdir: REFERENCE_ROOT.to_s)
  run_command!("git config user.email redwright-testing@example.local", chdir: REFERENCE_ROOT.to_s)
end

def reset_workspace_from_reference!
  FileUtils.rm_rf(PROJECTS_ROOT)
  FileUtils.mkdir_p(PROJECTS_ROOT)
  FileUtils.cp_r(REFERENCE_ROOT, PROJECT_ROOT)
end

def compose_protocols!(project, workspace_path:)
  catalog = ProjectProtocols::TemplateCatalog.new
  catalog.all_templates
  composition = ProjectProtocols::Composer.new(project: project, registry: catalog).call
  protocol = project.protocol || project.create_protocol!(status: "draft")
  expected_keys = composition.documents.map { |document| document.fetch("key") }
  existing_documents = protocol.documents.index_by(&:key)

  composition.documents.each do |document|
    protocol_document = existing_documents.fetch(document.fetch("key")) do
      protocol.documents.build(key: document.fetch("key"))
    end
    protocol_document.assign_attributes(
      path: document.fetch("path"),
      title: document.fetch("title"),
      layer: document.fetch("layer"),
      position: document.fetch("position"),
      body: document.fetch("body"),
      provenance: document.fetch("provenance", {})
    )
    protocol_document.save!
  end
  protocol.documents.where.not(key: expected_keys).destroy_all
  ProjectProtocols::FilesystemMaterializer.new(project: project, workspace_path: workspace_path.to_s).call
end

def create_scenario_records!
  project = Project.create!(
    name: PROJECT_NAME,
    description: "Deterministic Go CLI todo project for manual agent ticket execution.",
    root_path: PROJECT_ROOT.to_s,
    repo_url: "local://#{PROJECT_KEY}",
    stack_slug: "go"
  )
  ProjectAttribute.create!(
    project: project,
    key: "setup_context.language_runtime",
    value: "Go 1.22",
    source: "testing_scenario",
    weight: 5
  )

  board = Board.create!(project: project, name: "Go Todo Agent Board", project_key: PROJECT_KEY)
  columns = [
    ["backlog", "Backlog"],
    ["in_progress", "In Progress"],
    ["review", "Review"],
    ["blocked", "Blocked"]
  ].each_with_object({}).with_index do |((key, title), memo), index|
    memo[key] = board.columns.create!(key: key, title: title, position: index)
  end

  ticket = board.tickets.create!(
    column: columns.fetch("backlog"),
    title: TICKET_TITLE,
    description: <<~TEXT,
      Add a `done <task-number>` command to the Go todo CLI.

      Acceptance criteria:
      - `todo done 1` marks task 1 as done.
      - Existing open tasks remain unchanged.
      - `go test ./...` passes.
      - Use only the Go standard library.
    TEXT
    priority: :high,
    assignee: "agent-coder",
    kind: "task",
    severity: "low",
    scope: "runtime",
    source: "implementation"
  )

  compose_protocols!(project, workspace_path: REFERENCE_ROOT)
  run_command!("git add -A", chdir: REFERENCE_ROOT.to_s)
  run_command!("git commit -q -m #{Shellwords.escape("Initial commit")}", chdir: REFERENCE_ROOT.to_s)
  reset_workspace_from_reference!
  [project, board, ticket]
end

reset_development_database!
initialize_reference_workspace!
project, board, ticket = create_scenario_records!

puts "Agent ticket scenario reset."
puts "project_id=#{project.id}"
puts "board_id=#{board.id}"
puts "ticket_id=#{ticket.id}"
puts "reference=#{REFERENCE_ROOT}"
puts "workspace=#{PROJECT_ROOT}"
puts "telegram=/ticket start #{ticket.id}"
