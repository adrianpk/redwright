# frozen_string_literal: true

require "stringio"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/console/ingress_adapter"

class ConsoleIngressAdapterTest < Minitest::Test
  def test_poll_maps_stdin_line_into_canonical_event
    input = StringIO.new("hello world\n")
    output = StringIO.new
    adapter = Redwright::Console::IngressAdapter.new(input: input, output: output, local_chat_id: 42)

    poll = adapter.poll(cursor: nil, timeout_seconds: 0)
    assert_equal(1, poll.events.size)
    event = poll.events.first
    assert_equal(1, event.external_message_id)
    assert_equal(42, event.external_chat_id)
    assert_equal("hello world", event.text)
    assert_equal("console", event.transport)
    assert_equal("local", event.username)
    assert_equal(1, poll.next_cursor)
  end

  def test_poll_ignores_empty_lines
    input = StringIO.new("\n")
    output = StringIO.new
    adapter = Redwright::Console::IngressAdapter.new(input: input, output: output, local_chat_id: 7)

    poll = adapter.poll(cursor: nil, timeout_seconds: 0)
    assert_equal(0, poll.events.size)
    assert_equal(0, poll.next_cursor)
  end

  def test_send_message_writes_to_output
    input = StringIO.new
    output = StringIO.new
    adapter = Redwright::Console::IngressAdapter.new(input: input, output: output, local_chat_id: 7)

    response = adapter.send_message(chat_id: 7, text: "ok")
    assert_equal({ "ok" => true }, response)
    assert_equal("ok\n", output.string)
  end
end
