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

  test "create can link artifacts optionally" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-create-links")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    draft = create_document_artifact(project: board.project, artifact_type: "draft", title: "Draft Link", body: "draft")
    spec = create_document_artifact(project: board.project, artifact_type: "spec", title: "Spec Link", body: "spec", source_draft: draft, editable: false)

    post board_tickets_path(board), params: {
      ticket: {
        title: "Create endpoint with links",
        description: "Need a new endpoint",
        priority: "high",
        assignee: "agent-1",
        column_id: backlog.id,
        document_artifact_ids: [ draft.id, spec.id ]
      }
    }

    assert_redirected_to board_path(board)
    created = board.tickets.order(:created_at).last
    assert_equal [draft.id, spec.id].sort, created.document_artifact_ids.sort
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
    draft = create_document_artifact(project: board.project, artifact_type: "draft", title: "Draft A", body: "draft")
    spec = create_document_artifact(project: board.project, artifact_type: "spec", title: "Spec A", body: "spec", source_draft: draft, editable: false)
    plan = create_document_artifact(project: board.project, artifact_type: "plan_tracker", title: "Plan A", body: "plan", editable: false)
    ticket = board.tickets.create!(column: backlog, title: "Old title")
    ticket.ticket_artifact_links.create!(document_artifact: draft, role: "reference")

    patch ticket_path(ticket), params: {
      ticket: {
        title: "New title",
        priority: "low",
        document_artifact_ids: [ spec.id, plan.id ]
      }
    }

    assert_redirected_to board_path(board)
    assert_equal [spec.id, plan.id].sort, ticket.reload.document_artifact_ids.sort

    patch ticket_path(ticket), params: {
      ticket: {
        title: "No links",
        document_artifact_ids: [""]
      }
    }
    assert_redirected_to board_path(board)
    assert_empty ticket.reload.document_artifact_ids
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

    get new_board_ticket_path(board), headers: { "Turbo-Frame" => "modal" }

    assert_response :success
    assert_match('turbo-frame id="modal"', response.body)
  end

  test "edit returns modal frame payload for turbo frame requests" do
    admin = create_admin_user!
    sign_in_as(admin)
    board = create_board(project_key: "factory-modal-edit")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Modal target")

    get edit_ticket_path(ticket), headers: { "Turbo-Frame" => "modal" }

    assert_response :success
    assert_match('turbo-frame id="modal"', response.body)
    assert_match("Edit Ticket", response.body)
  end
end
