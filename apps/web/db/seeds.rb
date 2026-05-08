require "fileutils"
require "open3"
require "shellwords"

admin = User.find_by(email_address: "admin@redwright.local") || User.all.find(&:admin?) || User.new
admin.email_address = "admin@redwright.local"
admin.roles = ["admin"]
admin.password = "password-123"
admin.password_confirmation = "password-123"
admin.save!

project = Project.find_or_initialize_by(root_path: "/tmp/redwright-demo-factory")
project.assign_attributes(
  name: "Factory",
  description: "Default local Ruby demo project for board bootstrap.",
  repo_url: "https://example.local/redwright/demo-factory.git",
  stack_slug: "ruby"
)
project.save!

language_attribute = ProjectAttribute.find_or_initialize_by(project: project, key: "setup_context.language_runtime")
language_attribute.value = "Ruby 3.4"
language_attribute.weight = 5
language_attribute.source = "seed"
language_attribute.save!

board = Board.find_or_initialize_by(project_key: "demo-factory")
board.project = project
board.name = "Factory Board"
board.save!

columns = [
  ["backlog", "Backlog"],
  ["in_progress", "In Progress"],
  ["review", "Review"],
  ["approved", "Approved"]
]

columns.each_with_index do |(key, title), index|
  column = board.columns.find_or_initialize_by(key: key)
  column.title = title
  column.position = index
  column.save!
end

seeded_titles = [
  "CSV import: support semicolon delimiters",
  "Add empty-state guidance for new workspaces",
  "Fix drag-and-drop jitter on Firefox",
  "Persist selected board filter in URL",
  "Improve keyboard focus ring contrast",
  "Guard against duplicate ticket creation on slow network",
  "Normalize timestamps to user locale",
  "Hide archived tickets from pick-next endpoint",
  "Update docs labels from technical jargon"
]

board.tickets.where.not(title: seeded_titles).destroy_all

board.columns.where.not(key: columns.map(&:first)).find_each do |column|
  column.destroy! if column.tickets.empty?
end

labels = {
  "browser" => "#2563eb",
  "docs" => "#92400e",
  "i18n" => "#b45309",
  "import" => "#0f766e",
  "reliability" => "#be123c",
  "ux" => "#7c3aed",
  "workflow" => "#475569"
}

labels.each do |name, color|
  label = board.labels.find_or_initialize_by(name: name)
  label.color = color
  label.save!
end

def seed_ticket(board:, labels:, title:, column_key:, description:, priority:, assignee:, total: nil, review: nil, label_names: [])
  now = Time.current
  ticket = board.tickets.find_or_initialize_by(title: title)
  ticket.column = board.columns.find_by!(key: column_key)
  ticket.description = description
  ticket.priority = priority
  ticket.assignee = assignee
  ticket.started_at = total ? now - total : nil
  ticket.review_started_at = review ? now - review : nil
  ticket.sent_to_review_at = ticket.review_started_at if %w[review approved].include?(column_key)
  ticket.review_completed_at = review ? now : nil if column_key == "approved"
  ticket.merge_started_at = nil
  ticket.merged_at = nil
  ticket.archived_at = nil
  ticket.save!

  label_names.each do |label_name|
    TicketLabel.find_or_create_by!(ticket: ticket, label: labels.fetch(label_name))
  end

  ticket.ticket_labels.joins(:label).where.not(labels: {name: label_names}).destroy_all
end

def sync_project_protocol_from_templates(project, catalog)
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
end

def seed_project_document(project:, artifact_type:, title:, body:, source_draft: nil)
  document = project.documents.find_or_initialize_by(artifact_type: artifact_type, title: title)
  document.body = body
  document.editable = (artifact_type == "draft")
  document.source_draft = (artifact_type == "spec") ? source_draft : nil
  document.save!
  document
end

def seed_document_relation(from:, to:, relation_type:)
  DocumentRelation.find_or_create_by!(
    from_artifact: from,
    to_artifact: to,
    relation_type: relation_type
  )
end

def seed_demo_project_documents(project:)
  draft = seed_project_document(
    project: project,
    artifact_type: "draft",
    title: "Board Workflow Reliability Draft",
    body: <<~MARKDOWN
      # Board Workflow Reliability Draft

      ## Context

      The Factory demo project is a Ruby application with a kanban board used by humans and agents. The board already exposes realistic workflow tickets, but it needs a small reference artifact set so the Documents area feels connected to the work queue.

      ## Candidate Scope

      - Persist selected board filters in the URL so refreshes and shared links preserve context.
      - Prevent duplicate ticket creation when a slow network response makes a user retry the submit action.
      - Keep archived tickets out of pick-next flows so agents only receive active work.

      ## Related Tickets

      - Persist selected board filter in URL
      - Guard against duplicate ticket creation on slow network
      - Hide archived tickets from pick-next endpoint

      ## Open Questions

      - Which filter parameters are stable enough to become part of the URL contract?
      - Should duplicate ticket protection rely on an idempotency token, a server-side fingerprint, or both?
      - Should archived tickets be hidden only from agent assignment, or also from default board queries?
    MARKDOWN
  )

  spec = seed_project_document(
    project: project,
    artifact_type: "spec",
    title: "Board Workflow Reliability Spec",
    source_draft: draft,
    body: <<~MARKDOWN
      # Board Workflow Reliability Spec

      ## Objective

      Make board state and ticket assignment predictable enough for a Ruby-based agent workflow demo.

      ## Requirements

      1. Board filter state is represented in URL query parameters.
      2. Refreshing or sharing a filtered board URL restores the same visible filter state.
      3. Ticket creation rejects duplicate submissions produced by slow network retries.
      4. Pick-next assignment ignores archived tickets for both explicit and automatic assignee selection.

      ## Acceptance Criteria

      - A filtered board URL can be copied, opened in a new session, and rendered with the same filter values.
      - Repeating the same ticket creation request with the same idempotency key returns the original ticket instead of creating a second record.
      - Archived tickets are absent from pick-next results even when they have higher priority than active tickets.
      - Existing board drag-and-drop behavior remains unchanged.

      ## Out of Scope

      - New board analytics.
      - Bulk archive management.
      - A full saved-view system.
    MARKDOWN
  )

  plan_tracker = seed_project_document(
    project: project,
    artifact_type: "plan_tracker",
    title: "Board Workflow Reliability Plan Tracker",
    body: <<~MARKDOWN
      # Board Workflow Reliability Plan Tracker

      ## Delivery Slices

      - [ ] Slice 1: URL-backed board filter state.
      - [ ] Slice 2: Idempotent ticket creation guard.
      - [ ] Slice 3: Archived-ticket exclusion for pick-next.

      ## Tracking Notes

      - Start with controller/service coverage for the URL contract.
      - Add a model or service-level uniqueness guard for retry-safe ticket creation.
      - Verify pick-next behavior with archived high-priority tickets in the candidate pool.

      ## Current Status

      Seeded example. No implementation branch has been opened for this demo artifact.
    MARKDOWN
  )

  seed_document_relation(from: spec, to: draft, relation_type: "derives_from")
  seed_document_relation(from: plan_tracker, to: spec, relation_type: "tracks")
end

seed_ticket(
  board: board,
  labels: board.labels.index_by(&:name),
  title: "CSV import: support semicolon delimiters",
  column_key: "backlog",
  description: "Some customer exports use ; instead of , and currently fail parsing.",
  priority: :high,
  assignee: "product-dev-1",
  label_names: ["import"]
)

seed_ticket(
  board: board,
  labels: board.labels.index_by(&:name),
  title: "Add empty-state guidance for new workspaces",
  column_key: "backlog",
  description: "Show first-steps text when board has no tickets to reduce onboarding friction.",
  priority: :medium,
  assignee: "product-dev-2",
  label_names: ["ux"]
)

seed_ticket(
  board: board,
  labels: board.labels.index_by(&:name),
  title: "Fix drag-and-drop jitter on Firefox",
  column_key: "in_progress",
  description: "Ticket cards jump between columns when pointer crosses lane gaps quickly.",
  priority: :high,
  assignee: "frontend-1",
  total: 3.hours + 2.minutes,
  label_names: ["browser"]
)

seed_ticket(
  board: board,
  labels: board.labels.index_by(&:name),
  title: "Persist selected board filter in URL",
  column_key: "in_progress",
  description: "Keep lane/filter context after refresh or shareable links.",
  priority: :medium,
  assignee: "frontend-2",
  total: 1.hour + 52.minutes,
  label_names: ["workflow"]
)

seed_ticket(
  board: board,
  labels: board.labels.index_by(&:name),
  title: "Improve keyboard focus ring contrast",
  column_key: "approved",
  description: "Make focus states clear on ticket cards and modal controls.",
  priority: :low,
  assignee: "approver-3",
  total: 2.hours + 14.minutes,
  review: 42.minutes,
  label_names: ["ux"]
)

seed_ticket(
  board: board,
  labels: board.labels.index_by(&:name),
  title: "Guard against duplicate ticket creation on slow network",
  column_key: "review",
  description: "Double submit can create duplicates when response is delayed.",
  priority: :high,
  assignee: "reviewer-a",
  total: 6.hours + 2.minutes,
  review: 1.hour + 32.minutes,
  label_names: ["reliability"]
)

seed_ticket(
  board: board,
  labels: board.labels.index_by(&:name),
  title: "Normalize timestamps to user locale",
  column_key: "backlog",
  description: "Board currently mixes server time and local time in elapsed labels.",
  priority: :medium,
  assignee: "product-dev-3",
  label_names: ["i18n"]
)

seed_ticket(
  board: board,
  labels: board.labels.index_by(&:name),
  title: "Hide archived tickets from pick-next endpoint",
  column_key: "approved",
  description: "Archived work should never be considered for active assignment.",
  priority: :medium,
  assignee: "approver-1",
  total: 8.hours + 2.minutes,
  review: 2.hours,
  label_names: ["workflow"]
)

seed_ticket(
  board: board,
  labels: board.labels.index_by(&:name),
  title: "Update docs labels from technical jargon",
  column_key: "backlog",
  description: "Replace internal wording with user-facing terms in board and docs UI.",
  priority: :low,
  assignee: "docs-dev-1",
  label_names: ["docs"]
)

catalog = ProjectProtocols::TemplateCatalog.new
catalog.all_templates
sync_project_protocol_from_templates(project, catalog)
seed_demo_project_documents(project: project)

board.labels.where.not(name: labels.keys).find_each do |label|
  label.destroy! if label.tickets.empty?
end

def write_file(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content)
end

def run_seed_command!(command, chdir:)
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

def seed_go_todo_workspace(project_root)
  FileUtils.mkdir_p(project_root)
  write_file(File.join(project_root, ".gitignore"), "todo.txt\ntodo.test\ncoverage.out\n")
  write_file(File.join(project_root, "go.mod"), "module example.com/todo\n\ngo 1.22\n")
  write_file(File.join(project_root, "main.go"), go_todo_main)
  write_file(File.join(project_root, "main_test.go"), go_todo_test)
  write_file(
    File.join(project_root, "rw", "agent", "Dockerfile"),
    <<~DOCKERFILE
      FROM golang:1.22-alpine
      WORKDIR /workspace
      COPY . .
      RUN go test ./...
    DOCKERFILE
  )
  write_file(
    File.join(project_root, "rw", "agent", "runtime-setup.json"),
    JSON.pretty_generate(
      "purpose" => "agent_ticket_execution",
      "validation_commands" => ["go test ./..."],
      "runtime" => {"name" => "go", "version" => "1.22"}
    )
  )

  unless Dir.exist?(File.join(project_root, ".git"))
    run_seed_command!("git init -q", chdir: project_root)
    run_seed_command!("git config user.name redwright-seed", chdir: project_root)
    run_seed_command!("git config user.email redwright-seed@example.local", chdir: project_root)
  end
  run_seed_command!("git add -A", chdir: project_root)
  _stdout, _stderr, status = Open3.capture3("git diff --cached --quiet", chdir: project_root)
  return if status.success?

  run_seed_command!("git commit -q -m \"seed: initialize go todo cli\"", chdir: project_root)
end

def commit_seed_workspace_changes(project_root, message)
  run_seed_command!("git add -A", chdir: project_root)
  _stdout, _stderr, status = Open3.capture3("git diff --cached --quiet", chdir: project_root)
  return if status.success?

  run_seed_command!("git commit -q -m #{Shellwords.escape(message)}", chdir: project_root)
end

go_todo_root = Rails.root.join("..", "..", "_workspace", "Projects", "go-todo-agent").expand_path.to_s
seed_go_todo_workspace(go_todo_root)

go_project = Project.find_or_initialize_by(root_path: go_todo_root)
go_project.assign_attributes(
  name: "Go Todo Agent",
  description: "Seeded Go CLI todo project for manual agent ticket execution.",
  repo_url: "local://go-todo-agent",
  stack_slug: "go"
)
go_project.save!

go_language_attribute = ProjectAttribute.find_or_initialize_by(project: go_project, key: "setup_context.language_runtime")
go_language_attribute.value = "Go 1.22"
go_language_attribute.weight = 5
go_language_attribute.source = "seed"
go_language_attribute.save!

go_board = Board.find_or_initialize_by(project_key: "go-todo-agent")
go_board.project = go_project
go_board.name = "Go Todo Agent Board"
go_board.save!

go_columns = [
  ["backlog", "Backlog"],
  ["in_progress", "In Progress"],
  ["review", "Review"],
  ["blocked", "Blocked"]
]

go_columns.each_with_index do |(key, title), index|
  column = go_board.columns.find_or_initialize_by(key: key)
  column.title = title
  column.position = index
  column.save!
end

go_ticket = go_board.tickets.find_or_initialize_by(title: "Implement done command")
go_ticket.column = go_board.columns.find_by!(key: "backlog")
go_ticket.description = <<~TEXT
  Add a `done <task-number>` command to the Go todo CLI.

  Acceptance criteria:
  - `todo done 1` marks task 1 as done.
  - Existing open tasks remain unchanged.
  - `go test ./...` passes.
  - Use only the Go standard library.
TEXT
go_ticket.priority = :high
go_ticket.assignee = "agent-coder"
go_ticket.kind = "task"
go_ticket.severity = "low"
go_ticket.scope = "runtime"
go_ticket.source = "implementation"
go_ticket.started_at = nil
go_ticket.sent_to_review_at = nil
go_ticket.review_started_at = nil
go_ticket.review_completed_at = nil
go_ticket.archived_at = nil
go_ticket.save!

sync_project_protocol_from_templates(go_project, catalog)
commit_seed_workspace_changes(go_todo_root, "seed: materialize go todo protocols")
