# frozen_string_literal: true

require "stringio"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/tui/ingress_adapter"
require "redwright/tui/shell"

class TuiIngressAdapterTest < Minitest::Test
  def test_poll_maps_input_to_tui_event
    input = StringIO.new("create app\n")
    out = StringIO.new
    shell = Redwright::Tui::Shell.new(output: out)
    adapter = Redwright::Tui::IngressAdapter.new(input: input, shell: shell, local_chat_id: 9)

    poll = adapter.poll(cursor: nil, timeout_seconds: 0)
    assert_equal(1, poll.events.size)
    event = poll.events.first
    assert_equal("create app", event.text)
    assert_equal("tui", event.transport)
    assert_equal(9, event.external_chat_id)
    assert_equal(1, poll.next_cursor)
  end

  def test_send_message_renders_runtime_output
    input = StringIO.new
    out = StringIO.new
    shell = Redwright::Tui::Shell.new(output: out)
    adapter = Redwright::Tui::IngressAdapter.new(input: input, shell: shell, local_chat_id: 9)

    response = adapter.send_message(chat_id: 9, text: "done")
    assert_equal({ "ok" => true }, response)
    assert_includes(out.string, "rw> done")
  end
end
