# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/local_ipc_protocol"

class LocalIpcProtocolTest < Minitest::Test
  def test_decode_valid_send_request
    protocol = Redwright::LocalIpcProtocol.new
    req = protocol.decode_request('{"type":"send","session_id":"s1","payload":{"channel":"tui","text":"hi"}}')
    assert_equal("send", req["type"])
    assert_equal("s1", req["session_id"])
  end

  def test_decode_valid_ctl_request
    protocol = Redwright::LocalIpcProtocol.new
    req = protocol.decode_request('{"type":"ctl","session_id":"ctl-1","payload":{"channel":"ctl","command":"status"}}')
    assert_equal("ctl", req["type"])
    assert_equal("ctl-1", req["session_id"])
  end

  def test_decode_rejects_malformed_payload
    protocol = Redwright::LocalIpcProtocol.new
    err = assert_raises(ArgumentError) { protocol.decode_request('{"type":"send","session_id":"s1","payload":1}') }
    assert_equal("request_payload_not_object", err.message)
  end

  def test_encode_error_envelope
    protocol = Redwright::LocalIpcProtocol.new
    encoded = protocol.encode_envelope(type: "error", session_id: "s1", payload: { "code" => "bad_request" })
    assert_match("\"type\":\"error\"", encoded)
    assert_match("\"session_id\":\"s1\"", encoded)
  end
end
