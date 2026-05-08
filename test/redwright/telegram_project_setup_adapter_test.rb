# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/ingress_port"
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
      FakeApiResponse.new(body: command_body(name, payload))
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

    def command_body(name, payload)
      case name
      when "StartProjectSetup"
        slot = if payload["project_name"].to_s.empty?
                 "project_name"
               elsif payload["description"].to_s.empty?
                 "description"
               else
                 "project_type"
               end
        {
          "status" => "ok",
          "summary" => "Project setup started.",
          "session_id" => 41,
          "project_id" => nil,
          "state" => "collecting_context",
          "next_prompt" => nil,
          "data" => {
            "next_prompt_intent" => {
              "kind" => "setup_slot_question",
              "slot" => slot,
              "locale" => "auto",
              "llm_required" => true
            }
          }
        }
      when "AdvanceProjectSetup"
        {
          "status" => "ok",
          "summary" => "Project setup context updated.",
          "session_id" => 41,
          "project_id" => nil,
          "state" => "collecting_context",
          "next_prompt" => nil,
          "data" => {
            "next_prompt_intent" => {
              "kind" => "setup_slot_question",
              "slot" => "project_type",
              "locale" => "auto",
              "llm_required" => true
            }
          }
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
          "state" => "collecting_context",
          "next_prompt" => "What should this project do first?",
          "data" => {
            "setup_saga" => {
              "stage" => "questionnaire",
              "status" => "collecting",
              "materialization" => {"status" => "pending"},
              "initial_implementation" => {"status" => "pending", "runnable" => false},
              "ticket_operation" => {"status" => "pending"}
            }
          }
        }
      else
        raise "unexpected query #{name}"
      end
    end
  end

  class ScriptedRailsClient
    attr_reader :calls

    def initialize(command_bodies: {}, query_bodies: {})
      @command_bodies = command_bodies
      @query_bodies = query_bodies
      @calls = []
    end

    def command(name:, payload:, actor_identifier:, request_id:)
      @calls << { type: "command", name: name, payload: payload, actor_identifier: actor_identifier, request_id: request_id }
      FakeApiResponse.new(body: @command_bodies.fetch(name))
    end

    def query(name:, payload:, actor_identifier:, request_id:)
      @calls << { type: "query", name: name, payload: payload, actor_identifier: actor_identifier, request_id: request_id }
      FakeApiResponse.new(body: @query_bodies.fetch(name))
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
    refute_includes(client.calls.first[:payload].keys, "repository_input")
    assert_equal(41, client.calls.last[:payload].fetch("session_id"))
    assert_equal("acme/happy-cli", client.calls.last[:payload].fetch("answer"))
    refute_match(/^Next:/, started.message)
    assert_match("What type of project", advanced.message)
  end

  def test_routes_quoted_project_new_with_description_over_rails_api
    client = FakeRailsClient.new
    adapter = Redwright::TelegramProjectSetupAdapter.new(client: client)

    result = adapter.handle(
      ingress_event(1, '/project new "notes-cli" "A small command line notes manager with local file storage"'),
      trace_id: "trc-test"
    )

    assert result.handled?
    assert_equal(["StartProjectSetup"], client.calls.map { |call| call[:name] })
    assert_equal("notes-cli", client.calls.first[:payload].fetch("project_name"))
    assert_equal("notes-cli", client.calls.first[:payload].fetch("directory_name"))
    assert_equal("A small command line notes manager with local file storage", client.calls.first[:payload].fetch("description"))
    refute_includes(client.calls.first[:payload].keys, "repository_input")
    assert_equal("telegram:chat:9:user:77", client.calls.first[:actor_identifier])
    assert_equal("telegram-9-1-start-project-setup", client.calls.first[:request_id])
    assert_match("What type of project", result.message)
  end

  def test_routes_project_new_with_repository_url_as_optional_repository_context
    client = FakeRailsClient.new
    adapter = Redwright::TelegramProjectSetupAdapter.new(client: client)

    result = adapter.handle(
      event(1, "/project new notes-cli https://example.com/acme/notes-cli.git"),
      trace_id: "trc-test"
    )

    assert result.handled?
    assert_equal(["StartProjectSetup"], client.calls.map { |call| call[:name] })
    assert_equal("notes-cli", client.calls.first[:payload].fetch("project_name"))
    assert_equal("https://example.com/acme/notes-cli.git", client.calls.first[:payload].fetch("repository_input"))
    refute_includes(client.calls.first[:payload].keys, "description")
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
    assert_match("Setup stage: questionnaire", current.message)
    assert_match("Materialization: pending", current.message)
  end

  def test_ignores_non_project_messages_without_active_session
    adapter = Redwright::TelegramProjectSetupAdapter.new(client: FakeRailsClient.new)

    result = adapter.handle(event(1, "build something"), trace_id: "trc-test")

    refute result.handled?
  end

  def test_starts_project_setup_without_name_over_rails_api
    client = FakeRailsClient.new
    adapter = Redwright::TelegramProjectSetupAdapter.new(client: client)

    result = adapter.handle(event(1, "/project new"), trace_id: "trc-test")

    assert result.handled?
    assert_equal("project_new", result.command)
    assert_equal(["StartProjectSetup"], client.calls.map { |call| call[:name] })
    refute_includes(client.calls.first[:payload].keys, "project_name")
    refute_includes(client.calls.first[:payload].keys, "repository_input")
    assert_match("What should I call this project?", result.message)
  end

  def test_routes_setup_control_slash_to_active_session
    client = ScriptedRailsClient.new(
      command_bodies: {
        "StartProjectSetup" => {
          "status" => "ok",
          "summary" => "Project setup started.",
          "session_id" => 41,
          "project_id" => nil,
          "state" => "collecting_context",
          "data" => {
            "next_prompt_intent" => {
              "kind" => "setup_slot_question",
              "slot" => "description",
              "locale" => "auto",
              "llm_required" => true
            }
          }
        },
        "AdvanceProjectSetup" => {
          "status" => "ok",
          "summary" => "Project created; setup completed.",
          "session_id" => 41,
          "project_id" => 74,
          "state" => "completed",
          "data" => {
            "project" => {
              "id" => 74,
              "name" => "tiny-index"
            }
          }
        }
      }
    )
    adapter = Redwright::TelegramProjectSetupAdapter.new(client: client)

    adapter.handle(event(1, "/project new tiny-index"), trace_id: "trc-test")
    result = adapter.handle(event(2, "/done"), trace_id: "trc-test")

    assert result.handled?
    assert_equal(%w[StartProjectSetup AdvanceProjectSetup], client.calls.map { |call| call[:name] })
    assert_equal("/done", client.calls.last[:payload].fetch("answer"))
    assert_match("Project setup is complete.", result.message)
    refute_match(/\bState:/, result.message)
    refute_match(/\bSession:/, result.message)
    refute_match(/\bTrace:/, result.message)
  end

  def test_ignores_unknown_project_slash_without_active_session
    client = FakeRailsClient.new
    adapter = Redwright::TelegramProjectSetupAdapter.new(client: client)

    result = adapter.handle(event(1, "/project switch alpha"), trace_id: "trc-test")

    refute result.handled?
    assert_equal([], client.calls)
  end

  def test_where_without_active_context_is_handled_without_api_call
    client = FakeRailsClient.new
    adapter = Redwright::TelegramProjectSetupAdapter.new(client: client)

    result = adapter.handle(event(1, "/project where"), trace_id: "trc-test")

    assert result.handled?
    assert_match("No active Rails project setup session", result.message)
    assert_equal([], client.calls)
  end

  def test_terminal_setup_retains_project_context_for_where
    client = ScriptedRailsClient.new(
      command_bodies: {
        "StartProjectSetup" => {
          "status" => "ok",
          "summary" => "Project created; setup completed.",
          "session_id" => 50,
          "project_id" => 70,
          "state" => "completed",
          "next_prompt" => nil
        }
      },
      query_bodies: {
        "GetProject" => {
          "status" => "ok",
          "summary" => "Project retrieved.",
          "data" => {
            "project" => {
              "id" => 70,
              "name" => "happy-cli",
              "repo_url" => "https://github.com/acme/happy-cli.git",
              "setup_saga" => {
                "stage" => "ticket_operation",
                "status" => "ready",
                "materialization" => {
                  "status" => "materialized",
                  "validation_status" => "skipped",
                  "workspace" => {"relative_path" => "_workspace/Projects/happy-cli"}
                },
                "initial_implementation" => {"status" => "not_started", "runnable" => false},
                "ticket_operation" => {"status" => "available"}
              }
            }
          }
        }
      }
    )
    adapter = Redwright::TelegramProjectSetupAdapter.new(client: client)

    adapter.handle(event(1, "/project new happy-cli"), trace_id: "trc-test")
    current = adapter.handle(event(2, "/project where"), trace_id: "trc-test")

    assert current.handled?
    assert_equal(%w[StartProjectSetup GetProject], client.calls.map { |call| call[:name] })
    assert_match("Active Rails project: happy-cli (70)", current.message)
    assert_match("Repository: https://github.com/acme/happy-cli.git", current.message)
    assert_match("Setup stage: ticket operation", current.message)
    assert_match("Validation: skipped", current.message)
    assert_match("Workspace: _workspace/Projects/happy-cli", current.message)
  end

  def test_renders_project_lookup_failure
    client = ScriptedRailsClient.new(
      command_bodies: {
        "StartProjectSetup" => {
          "status" => "ok",
          "summary" => "Project created; setup completed.",
          "session_id" => 51,
          "project_id" => 71,
          "state" => "completed"
        }
      },
      query_bodies: {
        "GetProject" => {
          "status" => "error",
          "summary" => "project was not found",
          "data" => {}
        }
      }
    )
    adapter = Redwright::TelegramProjectSetupAdapter.new(client: client)

    adapter.handle(event(1, "/project new missing-project"), trace_id: "trc-test")
    current = adapter.handle(event(2, "/project where"), trace_id: "trc-test")

    assert_match("Project lookup failed: project was not found", current.message)
  end

  def test_renders_api_error_details
    client = ScriptedRailsClient.new(
      command_bodies: {
        "StartProjectSetup" => {
          "status" => "error",
          "summary" => "Project setup command is invalid.",
          "errors" => [
            {
              "code" => "invalid_project_name",
              "message" => "project_name can't be blank"
            }
          ]
        }
      }
    )
    adapter = Redwright::TelegramProjectSetupAdapter.new(client: client)

    result = adapter.handle(event(1, "/project new bad"), trace_id: "trc-test")

    assert result.handled?
    assert_match("Project setup error: Project setup command is invalid.", result.message)
    assert_match("- invalid_project_name: project_name can't be blank", result.message)
  end

  def test_routes_ticket_commands_through_rails_api_after_project_context_is_known
    client = ScriptedRailsClient.new(
      command_bodies: {
        "StartProjectSetup" => {
          "status" => "ok",
          "summary" => "Project created; setup completed.",
          "session_id" => 50,
          "project_id" => 70,
          "state" => "completed",
          "next_prompt" => nil
        },
        "ExecuteAgentTicket" => {
          "status" => "ok",
          "summary" => "Agent ticket execution completed.",
          "data" => {
            "execution" => {
              "mode" => "targeted",
              "state" => "completed",
              "ticket_id" => 42,
              "project_id" => 70,
              "acknowledgement" => {
                "status" => "accepted",
                "message" => "Agent ticket execution accepted.",
                "ticket_id" => 42,
                "mode" => "targeted"
              },
              "terminal_outcome" => {
                "status" => "ready_for_review",
                "ticket_id" => 42
              },
              "details" => {}
            }
          }
        }
      },
      query_bodies: {
        "GetTicketsByProject" => {
          "status" => "ok",
          "summary" => "Project tickets retrieved.",
          "data" => {
            "tickets" => [
              { "id" => 42, "title" => "Implement bridge", "column_key" => "backlog" }
            ]
          }
        },
        "PickNextTicket" => {
          "status" => "ok",
          "summary" => "Next ticket selected.",
          "data" => {
            "ticket_id" => 42,
            "ticket" => {
              "id" => 42,
              "title" => "Implement bridge",
              "column_key" => "backlog"
            }
          }
        }
      }
    )
    adapter = Redwright::TelegramProjectSetupAdapter.new(client: client)

    adapter.handle(event(1, "/project new happy-cli"), trace_id: "trc-test")
    listed = adapter.handle(event(2, "/ticket list"), trace_id: "trc-test")
    picked = adapter.handle(event(3, "/ticket pick"), trace_id: "trc-test")
    started = adapter.handle(event(4, "/ticket start 42"), trace_id: "trc-test")

    assert listed.handled?
    assert picked.handled?
    assert started.handled?
    assert_equal(%w[StartProjectSetup GetTicketsByProject PickNextTicket ExecuteAgentTicket], client.calls.map { |call| call[:name] })
    assert_equal(70, client.calls[1][:payload].fetch("project_id"))
    assert_equal(70, client.calls[2][:payload].fetch("project_id"))
    assert_equal("42", client.calls[3][:payload].fetch("ticket_id"))
    assert_match("- 42: Implement bridge [backlog]", listed.message)
    assert_match("Next ticket: Implement bridge (42)", picked.message)
    assert_equal(2, started.message_list.size)
    assert_match("Agent ticket execution accepted.", started.message_list.first)
    assert_match("Agent ticket execution finished.", started.message_list.last)
    assert_match("Outcome: ready_for_review", started.message_list.last)
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

  def ingress_event(update_id, text)
    Redwright::IngressEvent.new(
      external_message_id: update_id,
      external_chat_id: 9,
      sender_id: 77,
      username: "tester",
      text: text,
      transport: "telegram"
    )
  end
end
