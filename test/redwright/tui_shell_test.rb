# frozen_string_literal: true

require "stringio"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/tui/shell"

class TuiShellTest < Minitest::Test
  def test_render_includes_message_and_input_panels
    out = StringIO.new
    shell = Redwright::Tui::Shell.new(output: out, title: "RW")

    shell.enter!
    shell.add_user_message("hello")
    shell.add_runtime_message("ack")

    rendered = out.string
    assert_includes(rendered, "=== RW ===")
    assert_includes(rendered, "-- Messages --")
    assert_includes(rendered, "you> hello")
    assert_includes(rendered, "rw> ack")
    assert_includes(rendered, "-- Input --")
  end
end
