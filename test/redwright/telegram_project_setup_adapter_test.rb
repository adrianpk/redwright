# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/telegram_ingress"
require "redwright/telegram_project_setup_adapter"

class TelegramProjectSetupAdapterTest < Minitest::Test
  FakeApiResponse = Struct.new(:body, keyword_init: true)

  class FakeRailsClient
    attr_reader :calls

    def initialize
      @calls = []
    end

    def command(name:, payload:, actor_identifier:, request_id:)
      @calls << {
        type: "command",
        name: name,
        payload: payload,
        actor_identifier: actor_identifier,
        request_id: request_id
      }
      FakeApiResponse.new(body: command_body(name))
    end

    def query(name:, payload:, actor_identifier:, request_id:)
      @calls << {
        type: "query",
        name: name,
        payload: payload,
        actor_identifier: actor_identifier,
        request_id: request_id
      }
      FakeApiResponse.new(body: query_body(name))
    end

    private

    def command_body(name)
      case name
      when "StartProjectSetup"
        {
          "status" => "ok",
          "summary" => "Repository input requires clarification.",
          "session_id" => 41,
          "project_id" => nil,
          "state" => "awaiting_repository",
          "next_prompt" => "Repository input is ambiguous."
        }
      when "AdvanceProjectSetup"
        {
          "status" => "ok",
          "summary" => "Project setup advanced.",
          "session_id" => 41,
          "project_id" => nil,
          "state" => "awaiting_repository",
          "next_prompt" => "Repository input is ambiguous."
        }
      else
        raise "unexpected command #{name}"
      end
    end

    def query_body(name)
      case name
      when "ListProjects"
        {
          "status" => "ok",
          "summary" => "Projects retrieved.",
          "data" => {
            "projects" => [
              { "id" => 7, "name" => "rails-core" }
            ]
          }
        }
      when "GetProjectSetupSession"
        {
          "status" => "ok",
          "summary" => "Project setup session retrieved.",
          "session_id" => 41,
          "state" => "awaiting_repository",
          "next_prompt" => "Repository input is ambiguous."
        }
      else
        raise "unexpected query #{name}"
      end
    end
  end

  def test_starts_and_advances_project_setup_over_rails_api
    client = FakeRailsClient.new
    adapter = Redwright::TelegramProjectSetupAdapter.new(client: client)

    started = adapter.handle(
      event(1, "/project new happy-cli"),
      trace_id: "trc-test"
    )
    advanced = adapter.handle(
      event(2, "acme/happy-cli"),
      trace_id: "trc-test"
    )

    assert started.handled?
    assert advanced.handled?
    assert_equal(%w[StartProjectSetup AdvanceProjectSetup], client.calls.map { |call| call[:name] })
    assert_equal("happy-cli", client.calls.first[:payload].fetch("project_name"))
    assert_equal("happy-cli", client.calls.first[:payload].fetch("repository_input"))
    assert_equal(41, client.calls.last[:payload].fetch("session_id"))
    assert_equal("acme/happy-cli", client.calls.last[:payload].fetch("answer"))
    assert_match("Next: Repository input is ambiguous.", started.message)
    assert_match("Project setup advanced.", advanced.message)
  end

  def test_routes_project_list_and_where_through_rails_api
    client = FakeRailsClient.new
    adapter = Redwright::TelegramProjectSetupAdapter.new(client: client)

    adapter.handle(event(1, "/project new happy-cli"), trace_id: "trc-test")
    listed = adapter.handle(event(2, "/project list"), trace_id: "trc-test")
    current = adapter.handle(event(3, "/project where"), trace_id: "trc-test")

    assert listed.handled?
    assert current.handled?
    assert_equal(%w[StartProjectSetup ListProjects GetProjectSetupSession], client.calls.map { |call| call[:name] })
    assert_match("- rails-core (7)", listed.message)
    assert_match("Project setup session retrieved.", current.message)
  end

  def test_ignores_non_project_messages_without_active_session
    adapter = Redwright::TelegramProjectSetupAdapter.new(client: FakeRailsClient.new)

    result = adapter.handle(event(1, "build something"), trace_id: "trc-test")

    refute result.handled?
  end

  private

  def event(update_id, text)
    Redwright::TelegramEvent.new(
      update_id: update_id,
      chat_id: 9,
      user_id: 77,
      username: "tester",
      text: text
    )
  end
end
