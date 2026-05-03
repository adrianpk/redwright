require "test_helper"

$LOAD_PATH.unshift(File.expand_path("../../../../lib", __dir__))
require "redwright/ingress_port"
require "redwright/telegram_ingress"
require "redwright/telegram_project_setup_adapter"

class ProjectSetupTelegramE2eTest < ActiveSupport::TestCase
  ApiResponse = Struct.new(:body, keyword_init: true)

  class DispatcherClient
    def initialize
      @dispatcher = CommandQuery::ApplicationDispatcher.build
    end

    def command(name:, payload:, actor_identifier:, request_id:)
      call(kind: "command", name: name, payload: payload, actor_identifier: actor_identifier, request_id: request_id)
    end

    def query(name:, payload:, actor_identifier:, request_id:)
      call(kind: "query", name: name, payload: payload, actor_identifier: actor_identifier, request_id: request_id)
    end

    private

    def call(kind:, name:, payload:, actor_identifier:, request_id:)
      result = @dispatcher.call(
        {
          "kind" => kind,
          "name" => name,
          "payload" => payload,
          "execution_context" => {
            "actor_identifier" => actor_identifier,
            "source_channel" => "telegram"
          },
          "request_id" => request_id
        }
      )
      ApiResponse.new(body: response_body(result))
    end

    def response_body(result)
      body = deep_stringify(result.to_h)
      data = body.fetch("data")
      body.merge(
        "session_id" => data["session_id"],
        "project_id" => data["project_id"],
        "state" => data["state"],
        "next_prompt" => data["next_prompt"],
        "summary" => data["summary"] || body.dig("errors", 0, "message")
      )
    end

    def deep_stringify(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, item), result|
          result[key.to_s] = deep_stringify(item)
        end
      when Array
        value.map { |item| deep_stringify(item) }
      else
        value
      end
    end
  end

  test "telegram sparse setup starts without arguments and completes with defaults" do
    adapter = adapter_for_chat

    started = adapter.handle(event(1, "/project new"), trace_id: "trc-telegram-e2e")
    named = adapter.handle(event(2, "sparse-telegram"), trace_id: "trc-telegram-e2e")
    completed = adapter.handle(event(3, "/done"), trace_id: "trc-telegram-e2e")

    assert started.handled?
    assert named.handled?
    assert completed.handled?
    assert_match "What should I call this project?", started.message
    assert_match "What should this project do?", named.message
    assert_match "Project setup is complete.", completed.message
    project = Project.find(completed.api_response.fetch("project_id"))
    assert_equal "sparse-telegram", project.name
    assert_equal "manual", project.project_attributes.find_by!(key: "setup_context.agent_workflow_mode").value
  end

  test "telegram rich setup completes through the slot question loop" do
    adapter = adapter_for_chat

    start = adapter.handle(event(1, '/project new rich-telegram "A small API service for setup coverage"'), trace_id: "trc-telegram-e2e")
    type = adapter.handle(event(2, "API service"), trace_id: "trc-telegram-e2e")
    language = adapter.handle(event(3, "Ruby 3.4"), trace_id: "trc-telegram-e2e")
    framework = adapter.handle(event(4, "Rails"), trace_id: "trc-telegram-e2e")
    completed = adapter.handle(event(5, "SQLite"), trace_id: "trc-telegram-e2e")

    assert start.handled?
    assert type.handled?
    assert language.handled?
    assert framework.handled?
    assert completed.handled?
    assert_match "What type of project", start.message
    assert_match "What primary language", type.message
    assert_match "What framework", language.message
    assert_match "What main libraries", framework.message
    assert_match "Project setup is complete.", completed.message
    project = Project.find(completed.api_response.fetch("project_id"))
    assert_equal "rich-telegram", project.name
    assert_equal "Ruby 3.4", project.project_attributes.find_by!(key: "setup_context.language_runtime").value
    assert_equal "Rails", project.project_attributes.find_by!(key: "setup_context.framework").value
    assert_equal "SQLite", project.project_attributes.find_by!(key: "setup_context.libraries").value
  end

  test "telegram skip and done complete setup with defaultable slots" do
    adapter = adapter_for_chat

    start = adapter.handle(event(1, "/project new skip-telegram"), trace_id: "trc-telegram-e2e")
    skipped = adapter.handle(event(2, "/skip"), trace_id: "trc-telegram-e2e")
    completed = adapter.handle(event(3, "/done"), trace_id: "trc-telegram-e2e")

    assert start.handled?
    assert skipped.handled?
    assert completed.handled?
    assert_match "What should this project do?", start.message
    assert_match "What type of project", skipped.message
    project = Project.find(completed.api_response.fetch("project_id"))
    session = ProjectSetupSession.find(completed.api_response.fetch("session_id"))
    assert_equal "skip-telegram", project.name
    assert_equal "skipped", session.setup_slot("description").fetch("status")
    assert_equal "application", session.setup_slot("project_type").fetch("value")
  end

  test "telegram cancel leaves no project residue" do
    adapter = adapter_for_chat

    started = adapter.handle(event(1, "/project new"), trace_id: "trc-telegram-e2e")
    assert started.handled?

    assert_no_difference -> { Project.count } do
      cancelled = adapter.handle(event(2, "/cancel"), trace_id: "trc-telegram-e2e")
      assert cancelled.handled?
      assert_equal "cancelled", cancelled.api_response.fetch("state")
    end
  end

  test "telegram repository backed setup creates rails project context" do
    adapter = adapter_for_chat
    slug = "repo-telegram-#{SecureRandom.hex(4)}"

    result = adapter.handle(event(1, "/project new #{slug} https://example.com/acme/#{slug}.git"), trace_id: "trc-telegram-e2e")

    assert result.handled?
    assert_equal "collecting_alignment", result.api_response.fetch("state")
    assert_match "Project created; guided alignment is ready to continue.", result.message
    project = Project.find(result.api_response.fetch("project_id"))
    assert_equal slug, project.name
    assert_equal "https://example.com/acme/#{slug}.git", project.repo_url
  end

  private

  def adapter_for_chat
    Redwright::TelegramProjectSetupAdapter.new(client: DispatcherClient.new)
  end

  def event(update_id, text)
    Redwright::TelegramEvent.new(
      update_id: update_id,
      chat_id: 90_001,
      user_id: 77,
      username: "tester",
      text: text
    )
  end
end
