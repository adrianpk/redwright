require "test_helper"

class TicketFileIndexTest < ActiveSupport::TestCase
  test "ticket files own content and board state while SQL indexes metadata" do
    board = create_board
    ready = board.columns.create!(key: "backlog", title: "Ready", position: 0)
    done = board.columns.create!(key: "done", title: "Done", position: 1)
    ticket = board.tickets.create!(column: ready, title: "File ticket", description: "Original contract")
    assert_not_includes Ticket.column_names, "description"
    path = Pathname.new(board.project.root_path).join(ticket.relative_path)
    raw = path.read.sub("Original contract", "External contract").sub("column_key: backlog", "column_key: done").sub("status: ready", "status: solved")
    path.write(raw)
    Ticket.reconcile!(board.project)
    assert_equal "External contract", ticket.reload.description
    assert_equal done.id, ticket.column_id
    assert_equal "solved", ticket.workflow_status
    ticket.description = "Stale browser body"
    ticket.revision = "outdated"
    error = assert_raises(Specifications::Error) { ticket.save! }
    assert_equal :conflict, error.code
    assert_includes path.read, "External contract"
    path.delete
    assert_raises(Specifications::Error) { Ticket.reconcile!(board.project) }
    assert Ticket.exists?(ticket.id)
  end
end
