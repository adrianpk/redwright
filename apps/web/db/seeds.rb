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
FileUtils.mkdir_p(project.root_path)
Document.reconcile!(project)

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
  return ticket if ticket.persisted?
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

def seed_project_document(project:, artifact_type:, title:, body:)
  kind = {"draft" => "internal", "spec" => "spec", "plan_tracker" => "plan_tracker"}.fetch(artifact_type)
  existing = project.documents.find_by(artifact_type: kind, title: title)
  return existing if existing
  status = {"draft" => "active", "spec" => "approved", "plan_tracker" => "needs_review"}.fetch(artifact_type)
  use_case = project.use_cases.find_or_create_by!(name: "Board Workflow Reliability") { |feature| feature.description = "Reliable board operations." }
  project.documents.create!(artifact_type: kind, title: title, body: body, status: status, use_case: use_case)
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

FileUtils.mkdir_p(project.root_path)
ProjectProtocols::InitializationService.new(project: project).call
seed_demo_project_documents(project: project)

board.labels.where.not(name: labels.keys).find_each do |label|
  label.destroy! if label.tickets.empty?
end
