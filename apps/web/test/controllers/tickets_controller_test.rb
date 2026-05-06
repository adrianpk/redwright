require "test_helper"

class TicketsControllerTest < ActionDispatch::IntegrationTest
  def create_admin_user!
    User.create!(
      email_address: "owner@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
  end

  def create_programmer_user!
    user = User.new(
      email_address: "programmer@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
    user.roles = [ "programmer" ]
    user.save!
    user
  end

  test "create persists ticket from board form" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-create")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)

    post board_tickets_path(board), params: {
      ticket: {
        title: "Create endpoint",
        description: "Need a new endpoint",
        priority: "high",
        assignee: "agent-1",
        column_id: backlog.id
      }
    }

    assert_redirected_to board_path(board)
    created = board.tickets.order(:created_at).last
    assert_equal "Create endpoint", created.title
    assert_equal "high", created.priority
  end

  test "create persists aligned workflow metadata from board form" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-create-workflow")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)

    post board_tickets_path(board), params: {
      ticket: {
        title: "Create workflow ticket",
        description: "Need aligned metadata",
        priority: "high",
        column_id: backlog.id,
        kind: "task",
        severity: "medium",
        scope: "web",
        source: "manual_test",
        owner: "agent-reviewer",
        branch: "fix/ticket-123",
        pr: "https://codeberg.org/acme/redwright/pulls/123",
        commits: "abc123\n\ndef456"
      }
    }

    assert_redirected_to board_path(board)
    created = board.tickets.order(:created_at).last
    assert_equal "ready", created.workflow_status
    assert_equal "task", created.kind
    assert_equal "medium", created.severity
    assert_equal "web", created.scope
    assert_equal "manual_test", created.source
    assert_equal "agent-reviewer", created.owner
    assert_equal "fix/ticket-123", created.branch
    assert_equal "https://codeberg.org/acme/redwright/pulls/123", created.pr
    assert_equal [ "abc123", "def456" ], created.commits
  end

  test "create can link artifacts optionally" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-create-links")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    draft = create_document(project: board.project, artifact_type: "draft", title: "Draft Link", body: "draft")
    spec = create_document(project: board.project, artifact_type: "spec", title: "Spec Link", body: "spec", source_draft: draft, editable: false)

    post board_tickets_path(board), params: {
      ticket: {
        title: "Create endpoint with links",
        description: "Need a new endpoint",
        priority: "high",
        assignee: "agent-1",
        column_id: backlog.id,
        document_ids: [ draft.id, spec.id ]
      }
    }

    assert_redirected_to board_path(board)
    created = board.tickets.order(:created_at).last
    assert_equal [draft.id, spec.id].sort, created.document_ids.sort
    assert_equal "reference", created.ticket_document_links.find_by(document_id: draft.id).role
    assert_equal "primary_spec", created.ticket_document_links.find_by(document_id: spec.id).role
  end

  test "create can assign optional use case without changing document links" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-create-use-case")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    use_case = create_use_case(project: board.project, name: "Billing")
    draft = create_document(project: board.project, artifact_type: "draft", title: "Billing Draft", body: "draft")

    post board_tickets_path(board), params: {
      ticket: {
        title: "Use case ticket",
        description: "Scoped ticket",
        column_id: backlog.id,
        use_case_id: use_case.id,
        document_ids: [ draft.id ]
      }
    }

    assert_redirected_to board_path(board)
    created = board.tickets.order(:created_at).last
    assert_equal use_case.id, created.use_case_id
    assert_equal [draft.id], created.document_ids
  end

  test "create allows blank use case for project-level tickets" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-create-blank-use-case")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    create_use_case(project: board.project, name: "Billing")

    post board_tickets_path(board), params: {
      ticket: {
        title: "Project-level ticket",
        column_id: backlog.id,
        use_case_id: ""
      }
    }

    assert_redirected_to board_path(board)
    assert_nil board.tickets.order(:created_at).last.use_case_id
  end

  test "update edits existing ticket" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-update")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Old title")

    patch ticket_path(ticket), params: {
      ticket: { title: "New title", priority: "low" }
    }

    assert_redirected_to board_path(board)
    assert_equal "New title", ticket.reload.title
    assert_equal "low", ticket.priority
  end

  test "update can replace linked artifacts and allow empty list" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-update-links")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    draft = create_document(project: board.project, artifact_type: "draft", title: "Draft A", body: "draft")
    spec = create_document(project: board.project, artifact_type: "spec", title: "Spec A", body: "spec", source_draft: draft, editable: false)
    plan = create_document(project: board.project, artifact_type: "plan_tracker", title: "Plan A", body: "plan", editable: false)
    ticket = board.tickets.create!(column: backlog, title: "Old title")
    ticket.ticket_document_links.create!(document: draft, role: "reference")

    patch ticket_path(ticket), params: {
      ticket: {
        title: "New title",
        priority: "low",
        document_ids: [ spec.id, plan.id ]
      }
    }

    assert_redirected_to board_path(board)
    assert_equal [spec.id, plan.id].sort, ticket.reload.document_ids.sort
    assert_equal backlog.id, ticket.column_id
    assert_equal "primary_spec", ticket.ticket_document_links.find_by(document_id: spec.id).role
    assert_equal "plan_tracker", ticket.ticket_document_links.find_by(document_id: plan.id).role

    patch ticket_path(ticket), params: {
      ticket: {
        title: "No links",
        document_ids: [""]
      }
    }
    assert_redirected_to board_path(board)
    assert_empty ticket.reload.document_ids
  end

  test "update can change use case without changing document links" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-update-use-case")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    billing = create_use_case(project: board.project, name: "Billing")
    checkout = create_use_case(project: board.project, name: "Checkout")
    draft = create_document(project: board.project, artifact_type: "draft", title: "Linked Draft", body: "draft")
    ticket = board.tickets.create!(column: backlog, title: "Scoped ticket", use_case: billing)
    ticket.ticket_document_links.create!(document: draft, role: "reference")
    assert_equal [draft.id], ticket.reload.document_ids

    patch ticket_path(ticket), params: {
      ticket: {
        title: "Scoped ticket",
        use_case_id: checkout.id
      }
    }

    assert_redirected_to board_path(board)
    ticket.reload
    assert_equal checkout.id, ticket.use_case_id
    assert_equal [draft.id], ticket.document_ids
  end

  test "update can clear use case" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-clear-use-case")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    use_case = create_use_case(project: board.project, name: "Billing")
    ticket = board.tickets.create!(column: backlog, title: "Scoped ticket", use_case: use_case)

    patch ticket_path(ticket), params: {
      ticket: {
        title: "Project-level ticket",
        use_case_id: ""
      }
    }

    assert_redirected_to board_path(board)
    assert_nil ticket.reload.use_case_id
  end

  test "rejects cross-project use case assignment" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-cross-use-case")
    other_project = create_project(key: "factory-cross-use-case-other")
    foreign_use_case = create_use_case(project: other_project, name: "Foreign")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)

    post board_tickets_path(board), params: {
      ticket: {
        title: "Invalid scoped ticket",
        column_id: backlog.id,
        use_case_id: foreign_use_case.id
      }
    }

    assert_response :unprocessable_entity
    assert_equal 0, board.tickets.count
    assert_includes response.body, "Use case must belong to the same project"
  end

  test "move updates ticket column and returns turbo stream" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    review = board.columns.create!(key: "review", title: "Review", position: 1)
    ticket = board.tickets.create!(column: backlog, title: "Create model")

    patch move_ticket_path(ticket, format: :turbo_stream),
      params: { column_id: review.id }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.media_type + "; charset=utf-8"
    assert_equal review.id, ticket.reload.column_id
  end

  test "pick returns assignee-prioritized ticket" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    board.tickets.create!(column: backlog, title: "General high", priority: :high)
    selected = board.tickets.create!(column: backlog, title: "Mine medium", priority: :medium, assignee: "agent-1")

    get pick_board_tickets_path(board), params: { assignee: "agent-1" }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal selected.id, json.fetch("id")
    assert_equal board.project_id, json.fetch("project_id")
  end

  test "archive removes ticket from board scope" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-archive")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Archive me")

    patch archive_ticket_path(ticket, format: :turbo_stream)

    assert_response :success
    assert_not_nil ticket.reload.archived_at
    assert_equal 0, board.tickets.visible_on_board.count
  end

  test "destroy removes ticket from database" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-delete")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Delete me")

    delete ticket_path(ticket, format: :turbo_stream)

    assert_response :success
    assert_nil Ticket.find_by(id: ticket.id)
  end

  test "non-admin cannot assign ticket on create" do
    create_admin_user!
    programmer = create_programmer_user!
    sign_in_as(programmer)
    board = create_board(project_key: "factory-assign-create")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)

    post board_tickets_path(board), params: {
      ticket: {
        title: "Assign blocked",
        assignee: "agent-1",
        column_id: backlog.id
      }
    }

    assert_response :redirect
    assert_equal 0, board.tickets.count
  end

  test "non-admin can create ticket when assignee is omitted" do
    create_admin_user!
    programmer = create_programmer_user!
    sign_in_as(programmer)
    board = create_board(project_key: "factory-non-admin-create")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)

    post board_tickets_path(board), params: {
      ticket: {
        title: "Allowed create",
        description: "No assignee set",
        column_id: backlog.id
      }
    }

    assert_redirected_to board_path(board)
    created = board.tickets.order(:created_at).last
    assert_equal "Allowed create", created.title
    assert_equal("", created.assignee.to_s)
  end

  test "non-admin cannot archive or delete" do
    create_admin_user!
    programmer = create_programmer_user!
    sign_in_as(programmer)
    board = create_board(project_key: "factory-governance")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Governance target")

    patch archive_ticket_path(ticket, format: :turbo_stream)
    assert_response :forbidden
    assert_nil ticket.reload.archived_at

    delete ticket_path(ticket, format: :turbo_stream)
    assert_response :forbidden
    assert_not_nil Ticket.find_by(id: ticket.id)
  end

  test "non-admin can update ticket fields when assignee is unchanged" do
    create_admin_user!
    programmer = create_programmer_user!
    sign_in_as(programmer)
    board = create_board(project_key: "factory-non-admin-update")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Old title", assignee: "")

    patch ticket_path(ticket), params: {
      ticket: { title: "New title", priority: "high" }
    }

    assert_redirected_to board_path(board)
    assert_equal "New title", ticket.reload.title
  end

  test "new returns modal frame payload for turbo frame requests" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-modal-new")
    board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    create_document(project: board.project, artifact_type: "draft", title: "Draft Candidate", body: "draft")
    create_use_case(project: board.project, name: "Billing")

    get new_board_ticket_path(board), headers: { "Turbo-Frame" => "modal" }

    assert_response :success
    assert_match('turbo-frame id="modal"', response.body)
    assert_match("modal-size-toggle", response.body)
    assert_match("ticket-form-layout", response.body)
    assert_match("ticket-form-sidebar", response.body)
    assert_match("Workflow Status", response.body)
    assert_match("Delivery", response.body)
    assert_match("Use Case", response.body)
    assert_match("Billing", response.body)
    assert_match("Project-level", response.body)
    assert_match("data-ticket-document-picker", response.body)
    assert_match("Draft Candidate (draft)", response.body)
  end

  test "edit returns modal frame payload for turbo frame requests" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-modal-edit")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Modal target")
    use_case = create_use_case(project: board.project, name: "Billing")
    ticket.update!(use_case: use_case)
    draft = create_document(project: board.project, artifact_type: "draft", title: "Linked Draft", body: "draft")
    ticket.ticket_document_links.create!(document: draft, role: "reference")

    get edit_ticket_path(ticket), headers: { "Turbo-Frame" => "modal" }

    assert_response :success
    assert_match('turbo-frame id="modal"', response.body)
    assert_match("Edit Ticket", response.body)
    assert_match("modal-size-toggle", response.body)
    assert_match("ticket-document-chip", response.body)
    assert_match("Linked Draft (draft)", response.body)
    assert_match('data-ticket-document-remove', response.body)
    assert_match("Billing", response.body)
  end

  test "edit renders markdown preview for ticket description" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-modal-markdown-preview")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Modal target", description: "Hola **Adrian**")

    get edit_ticket_path(ticket), headers: { "Turbo-Frame" => "modal" }

    assert_response :success
    assert_includes response.body, "<strong>Adrian</strong>"
    assert_includes response.body, "ticket-description-preview"
  end

  test "comment creates ticket comment with markdown and mention metadata" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-comment-create")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Comment target")

    post comments_ticket_path(ticket), params: {
      ticket_comment: {
        body: "Hello **Adrian**. Ping @agent."
      }
    }

    assert_redirected_to edit_ticket_path(ticket)
    comment = ticket.ticket_comments.last
    assert_equal "Hello **Adrian**. Ping @agent.", comment.body
    assert_equal "user", comment.author_type
    assert_equal admin.id, comment.author_id
    assert_equal "owner@example.com", comment.author_label
    assert_equal [ "agent" ], comment.mentions.pluck(:handle)
  end

  test "edit renders ticket comments as markdown" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-comment-render")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Comment target")
    ticket.ticket_comments.create!(
      author_type: "agent",
      author_label: "agent-coder",
      body: "Please review **this** with @owner."
    )

    get edit_ticket_path(ticket), headers: { "Turbo-Frame" => "modal" }

    assert_response :success
    assert_includes response.body, "Comments"
    assert_includes response.body, "<strong>this</strong>"
    assert_includes response.body, "@owner"
  end

  test "markdown preview endpoint renders sanitized html" do
    admin = create_admin_user!
    sign_in_as(admin)

    post markdown_preview_tickets_path, params: { text: %(Hola **Adrian**\n\n<script>alert("x")</script>) }, as: :json

    assert_response :success
    assert_includes response.body, "<strong>Adrian</strong>"
    assert_no_match(/<script>alert/i, response.body)
  end
end
