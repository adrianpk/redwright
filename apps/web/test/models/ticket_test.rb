require "test_helper"

class TicketTest < ActiveSupport::TestCase
  test "defaults workflow metadata from the board column without requiring accessory fields" do
    board = create_board(project_key: "factory-workflow-defaults")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)

    ticket = board.tickets.create!(column: backlog, title: "Minimal ticket")

    assert_equal "ready", ticket.workflow_status
    assert_equal "unclassified", ticket.kind
    assert_equal "unclassified", ticket.severity
    assert_equal "unclassified", ticket.scope
    assert_equal "chat", ticket.source
    assert_equal [], ticket.commits
    assert_not_nil ticket.ready_at
  end

  test "assigns and resolves human ticket keys independently from row ids" do
    board = create_board(project_key: "factory-human-key")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)

    first = board.tickets.create!(column: backlog, title: "First keyed ticket")
    second = board.tickets.create!(column: backlog, title: "Second keyed ticket")

    assert_match(/\ARW-\d+\z/, first.human_key)
    assert_match(/\ARW-\d+\z/, second.human_key)
    assert_not_equal first.human_key, second.human_key
    assert_equal first, Ticket.resolve_ref(first.human_key.downcase)
    assert_equal second, Ticket.resolve_ref(second.id.to_s)
    assert_equal first.human_key, first.display_key
  end

  test "transition_to_column stamps review and merge phase times" do
    board = create_board(project_key: "factory")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    review = board.columns.create!(key: "review", title: "Review", position: 1)
    merged = board.columns.create!(key: "merged", title: "Merged", position: 2)
    ticket = board.tickets.create!(column: backlog, title: "Implement parser", priority: :high)

    ticket.transition_to_column!(review)
    assert_equal "reviewing", ticket.workflow_status
    assert_not_nil ticket.sent_to_review_at
    assert_not_nil ticket.review_started_at

    ticket.transition_to_column!(merged)
    assert_equal "solved", ticket.workflow_status
    assert_not_nil ticket.merge_started_at
    assert_not_nil ticket.merged_at
    assert_not_nil ticket.closed_at
  end

  test "accepts aligned optional workflow fields and validates enums" do
    board = create_board(project_key: "factory-workflow-fields")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)

    ticket = board.tickets.create!(
      column: backlog,
      title: "Aligned fields",
      kind: "bug",
      severity: "high",
      scope: "web",
      source: "manual_test",
      owner: "agent-reviewer",
      branch: "fix/ticket-1",
      pr: "https://codeberg.org/acme/repo/pulls/1",
      commits: [ "abc123" ]
    )

    assert_equal "ready", ticket.workflow_status
    assert_equal "bug", ticket.kind
    assert_equal "high", ticket.severity
    assert_equal "web", ticket.scope
    assert_equal "manual_test", ticket.source
    assert_equal [ "abc123" ], ticket.commits

    invalid = Ticket.new(title: "Invalid status", workflow_status: "unknown")
    assert_not invalid.valid?
    assert_includes invalid.errors[:workflow_status], "is not included in the list"
  end

  test "resolution requires terminal workflow status" do
    board = create_board(project_key: "factory-workflow-resolution")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    merged = board.columns.create!(key: "merged", title: "Merged", position: 1)
    ticket = board.tickets.create!(column: backlog, title: "Resolution ticket")

    ticket.resolution = "fixed"

    assert_not ticket.valid?
    assert_includes ticket.errors[:resolution], "can only be set for solved or closed tickets"

    ticket.column = merged
    assert ticket.valid?
    assert_equal "solved", ticket.workflow_status
  end

  test "pick_next_for prefers assignee and falls back to highest priority" do
    board = create_board(project_key: "factory")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    board.columns.create!(key: "merged", title: "Merged", position: 1)

    board.tickets.create!(column: backlog, title: "General low", priority: :low)
    high = board.tickets.create!(column: backlog, title: "General high", priority: :high)
    assigned = board.tickets.create!(column: backlog, title: "Mine medium", priority: :medium, assignee: "agent-1")

    assert_equal assigned.id, Ticket.pick_next_for(board: board, assignee: "agent-1").id
    assert_equal high.id, Ticket.pick_next_for(board: board, assignee: "agent-2").id
  end

  test "derives project context through board association" do
    board = create_board(project_key: "factory-project-ctx")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Project context")

    assert_equal board.project_id, ticket.project_id
    assert_equal board.project.id, ticket.project.id
  end

  test "for_project scope resolves tickets by board project" do
    board_a = create_board(project_key: "factory-proj-a")
    board_b = create_board(project_key: "factory-proj-b")
    backlog_a = board_a.columns.create!(key: "backlog", title: "Backlog", position: 0)
    backlog_b = board_b.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket_a = board_a.tickets.create!(column: backlog_a, title: "Ticket A")
    board_b.tickets.create!(column: backlog_b, title: "Ticket B")

    scoped_ids = Ticket.for_project(board_a.project_id).pluck(:id)
    assert_includes scoped_ids, ticket_a.id
    assert_equal 1, scoped_ids.size
  end

  test "project context optional invariant matches board project" do
    board = create_board(project_key: "factory-invariant")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Invariant ticket")

    assert ticket.project_context_consistent?(board.project_id)
    assert_not ticket.project_context_consistent?(board.project_id + 1)
  end

  test "use case must belong to ticket project" do
    board = create_board(project_key: "factory-ticket-use-case")
    other_project = create_project(key: "factory-ticket-other-project")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    other_use_case = create_use_case(project: other_project, name: "External")

    ticket = board.tickets.new(column: backlog, title: "Invalid use case", use_case: other_use_case)

    assert_not ticket.valid?
    assert_includes ticket.errors[:use_case], "must belong to the same project"
  end

  test "tags ticket with denormalized project and use case scope" do
    board = create_board(project_key: "factory-ticket-tags")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    use_case = create_use_case(project: board.project, name: "Billing")
    ticket = board.tickets.create!(column: backlog, title: "Tagged ticket", use_case: use_case)

    ticket.tag_with!("Billing Context")

    tagging = ticket.taggings.first
    assert_equal ["billing-context"], ticket.tags.map(&:name)
    assert_equal board.project_id, tagging.project_id
    assert_equal use_case.id, tagging.use_case_id
  end
end
