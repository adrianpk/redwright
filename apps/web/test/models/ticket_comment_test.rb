require "test_helper"

class TicketCommentTest < ActiveSupport::TestCase
  test "captures user agent and unresolved mentions" do
    user = User.create!(
      email_address: "adrian@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
    board = create_board(project_key: "ticket-comment-mentions")
    column = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: column, title: "Comment target")

    comment = ticket.ticket_comments.create!(
      author_type: "agent",
      author_label: "agent-coder",
      body: "Please check this, @adrian and @agent-coder. Unknown: @reviewer."
    )

    mentions = comment.mentions.order(:handle)
    assert_equal %w[adrian agent-coder reviewer], mentions.map(&:handle)
    assert_equal "user", mentions.find { |mention| mention.handle == "adrian" }.target_type
    assert_equal user.id, mentions.find { |mention| mention.handle == "adrian" }.target_id
    assert_equal "agent", mentions.find { |mention| mention.handle == "agent-coder" }.target_type
    assert_equal "unresolved", mentions.find { |mention| mention.handle == "reviewer" }.target_type
  end
end
