# frozen_string_literal: true

require "json"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/telegram_rails_api_client"

class TelegramRailsApiClientTest < Minitest::Test
  FakeResponse = Struct.new(:code, :body, keyword_init: true)

  def test_posts_command_envelope_to_rails_api
    captured = []
    transport = lambda do |uri:, headers:, body:|
      captured << { uri: uri, headers: headers, body: JSON.parse(body) }
      FakeResponse.new(
        code: "200",
        body: JSON.generate({ "status" => "ok", "request_id" => "req-1" })
      )
    end
    client = Redwright::TelegramRailsApiClient.new(
      base_url: "http://127.0.0.1:3000/api/v1",
      transport: transport
    )

    response = client.command(
      name: "StartProjectSetup",
      payload: { "project_name" => "happy-cli" },
      actor_identifier: "telegram:chat:9:user:1",
      request_id: "req-1"
    )

    assert response.ok?
    assert_equal("http://127.0.0.1:3000/api/v1/commands", captured.first[:uri].to_s)
    assert_equal("telegram:chat:9:user:1", captured.first[:headers]["X-Redwright-Actor"])
    assert_equal("telegram", captured.first[:headers]["X-Redwright-Source"])
    assert_equal("StartProjectSetup", captured.first[:body].fetch("name"))
    assert_equal({ "project_name" => "happy-cli" }, captured.first[:body].fetch("payload"))
  end

  def test_posts_query_envelope_to_rails_api
    captured = []
    transport = lambda do |uri:, headers:, body:|
      captured << { uri: uri, headers: headers, body: JSON.parse(body) }
      FakeResponse.new(
        code: "200",
        body: JSON.generate({ "status" => "ok", "request_id" => "req-2" })
      )
    end
    client = Redwright::TelegramRailsApiClient.new(
      base_url: "http://127.0.0.1:3000/api/v1/",
      transport: transport
    )

    response = client.query(
      name: "ListProjects",
      payload: {},
      actor_identifier: "telegram:chat:9:user:1",
      request_id: "req-2"
    )

    assert response.ok?
    assert_equal("http://127.0.0.1:3000/api/v1/queries", captured.first[:uri].to_s)
    assert_equal("ListProjects", captured.first[:body].fetch("name"))
    assert_equal("req-2", response.body.fetch("request_id"))
  end
end
