require "test_helper"

class TicketDocumentLinkTest < ActiveSupport::TestCase
  test "requires linked document to belong to ticket project" do
    board = create_board(project_key: "ticket-link-project")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Cross project guard")
    foreign_document = create_document(
      project: create_project(key: "foreign-doc-project"),
      artifact_type: "draft",
      title: "Foreign Doc"
    )

    link = TicketDocumentLink.new(ticket: ticket, document: foreign_document, role: "reference")

    assert_not link.valid?
    assert_includes link.errors[:document], "must belong to the same project as ticket"
  end

  test "primary_spec role requires spec document" do
    board = create_board(project_key: "ticket-link-role-spec")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Role contract")
    draft = create_document(project: board.project, artifact_type: "draft", title: "Draft")

    link = TicketDocumentLink.new(ticket: ticket, document: draft, role: "primary_spec")

    assert_not link.valid?
    assert_includes link.errors[:role], "requires a spec document"
  end

  test "plan_tracker role requires plan_tracker document" do
    board = create_board(project_key: "ticket-link-role-plan")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Role contract")
    draft = create_document(project: board.project, artifact_type: "draft", title: "Draft")

    link = TicketDocumentLink.new(ticket: ticket, document: draft, role: "plan_tracker")

    assert_not link.valid?
    assert_includes link.errors[:role], "requires a plan_tracker document"
  end
end
