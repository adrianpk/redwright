require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "ticket markdown renders formatting" do
    rendered = ticket_markdown("Use **bold** and `code`.\n\n- one\n- two")

    assert_includes rendered, "<strong>bold</strong>"
    assert_includes rendered, "<code>code</code>"
    assert_includes rendered, "<li>one</li>"
    assert_includes rendered, "<li>two</li>"
  end

  test "ticket markdown sanitizes unsafe html" do
    rendered = ticket_markdown(%(<script>alert("x")</script>[bad](javascript:alert("x"))))

    assert_no_match(/script/i, rendered)
    assert_no_match(/javascript:/i, rendered)
  end
end
