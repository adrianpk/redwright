# frozen_string_literal: true

require "json"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/telegram_client"

class TelegramClientTest < Minitest::Test
  class FakeHttp
    attr_reader :captured_uri

    def initialize(response)
      @response = response
    end

    def get_response(uri)
      @captured_uri = uri
      @response
    end
  end

  FakeResponse = Struct.new(:code, :body)

  def test_get_updates_successfully_parses_payload_and_query
    response = FakeResponse.new("200", JSON.dump({ ok: true, result: [{ "update_id" => 1 }] }))
    http = FakeHttp.new(response)
    client = Redwright::TelegramClient.new(bot_token: "abc", http: http)

    updates = client.get_updates(offset: 99, timeout_seconds: 5)

    assert_equal([{ "update_id" => 1 }], updates)
    assert_match("/botabc/getUpdates", http.captured_uri.path)
    assert_match("offset=99", http.captured_uri.query)
    assert_match("timeout=5", http.captured_uri.query)
  end

  def test_get_updates_raises_on_non_ok_response
    response = FakeResponse.new("500", "boom")
    client = Redwright::TelegramClient.new(bot_token: "abc", http: FakeHttp.new(response))

    err = assert_raises(RuntimeError) { client.get_updates(timeout_seconds: 1) }
    assert_match("http 500", err.message)
  end
end
