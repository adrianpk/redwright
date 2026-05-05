require "test_helper"
require "tmpdir"
require "yaml"

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

  test "telegram completion creates planned fallback workspace and avoids shortcode artifacts" do
    with_local_projects_root do |projects_root|
      adapter = adapter_for_chat

      start = adapter.handle(event(1, '/project new workspace-telegram "A CLI that writes local notes"'), trace_id: "trc-telegram-e2e")
      type = adapter.handle(event(2, "CLI"), trace_id: "trc-telegram-e2e")
      language = adapter.handle(event(3, "Ruby 3.4"), trace_id: "trc-telegram-e2e")
      framework = adapter.handle(event(4, "none"), trace_id: "trc-telegram-e2e")
      completed = adapter.handle(event(5, "Thor and SQLite"), trace_id: "trc-telegram-e2e")

      assert start.handled?
      assert type.handled?
      assert language.handled?
      assert framework.handled?
      assert completed.handled?
      refute_match(/:[a-z0-9_+-]+:/i, completed.message)
      assert_match "Project setup is complete.", completed.message
      assert_match "_workspace/Projects/workspace-telegram", completed.message

      workspace = completed.api_response.dig("data", "workspace")
      assert_equal File.join(projects_root, "workspace-telegram"), workspace.fetch("path")
      assert File.directory?(workspace.fetch("path"))
      manifest_path = workspace.fetch("manifest_path")
      assert File.file?(manifest_path)

      project = Project.find(completed.api_response.fetch("project_id"))
      manifest = YAML.safe_load(File.read(manifest_path))
      assert_equal project.id, manifest.dig("rails", "project_id")
      assert_equal "workspace-telegram", manifest.dig("project", "name")
      assert_equal "Ruby 3.4", manifest.dig("setup_context", "slots", "language_runtime", "value")
      assert_equal "Thor and SQLite", manifest.dig("setup_context", "slots", "libraries", "value")
      assert_equal "materialized_planned", manifest.dig("materialization", "status")
      assert_equal false, manifest.dig("materialization", "runnable")
      assert_equal "planned", manifest.dig("initial_implementation", "status")
      assert_equal "skipped", manifest.dig("validation", "status")
      assert File.file?(workspace.fetch("readme_path"))
      assert File.file?(workspace.fetch("setup_notes_path"))
      refute File.exist?(File.join(workspace.fetch("path"), "go.mod"))
      assert_match "Initial implementation: planned", completed.message
      assert_match "Runnable: no", completed.message
      assert_match "Validation: skipped", completed.message
    end
  end

  test "telegram go cli setup creates scaffold and reports closure outcome" do
    with_local_projects_root do |projects_root|
      adapter = adapter_for_chat

      start = adapter.handle(event(1, '/project new go-telegram "A small Go CLI for setup closure"'), trace_id: "trc-telegram-e2e")
      type = adapter.handle(event(2, "CLI"), trace_id: "trc-telegram-e2e")
      language = adapter.handle(event(3, "Go 1.22"), trace_id: "trc-telegram-e2e")
      framework = adapter.handle(event(4, "none"), trace_id: "trc-telegram-e2e")
      completed = adapter.handle(event(5, "standard library"), trace_id: "trc-telegram-e2e")

      assert start.handled?
      assert type.handled?
      assert language.handled?
      assert framework.handled?
      assert completed.handled?
      assert_match "Project setup is complete.", completed.message
      assert_match "_workspace/Projects/go-telegram", completed.message
      assert_match "Initial implementation: scaffolded", completed.message
      assert_match(/Materialization: materialized (runnable|scaffolded|failed)/, completed.message)
      assert_match(/Runnable: (yes|no)/, completed.message)
      assert_match(/Validation: (passed|skipped|failed)/, completed.message)

      workspace = completed.api_response.dig("data", "workspace")
      assert_equal File.join(projects_root, "go-telegram"), workspace.fetch("path")
      assert_equal "go_cli", workspace.fetch("scaffold_profile")
      assert_equal %w[go.mod main.go main_test.go], workspace.fetch("scaffold_files")
      assert File.file?(File.join(workspace.fetch("path"), "go.mod"))
      assert File.file?(File.join(workspace.fetch("path"), "main.go"))
      assert File.file?(File.join(workspace.fetch("path"), "main_test.go"))

      manifest = YAML.safe_load(File.read(workspace.fetch("manifest_path")))
      assert_equal "go_cli", manifest.dig("scaffold", "profile")
      assert_equal "example.com/redwright/go-telegram", manifest.dig("scaffold", "module_path")
      assert_equal %w[go.mod main.go main_test.go], manifest.dig("scaffold", "files")
      assert_includes %w[passed skipped failed], manifest.dig("validation", "status")
      assert_equal manifest.dig("validation", "status"), workspace.fetch("validation_status")
      assert_equal manifest.dig("materialization", "runnable"), workspace.fetch("runnable")
      assert_equal workspace.fetch("materialization_status"), completed.api_response.dig("data", "setup_saga", "materialization", "status")
    end
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
    assert_match "What primary outcome should this project optimize for first?", result.message
    project = Project.find(result.api_response.fetch("project_id"))
    assert_equal slug, project.name
    assert_equal "https://example.com/acme/#{slug}.git", project.repo_url
  end

  test "telegram quiz opens project quiz and records answer" do
    adapter = adapter_for_chat
    project = create_project(key: "telegram-quiz-project")
    adapter.handle(event(1, "/project list"), trace_id: "trc-telegram-e2e")
    adapter.handle(event(2, "/project where"), trace_id: "trc-telegram-e2e")
    adapter.instance_variable_get(:@project_ids_by_chat)[90_001] = project.id

    opened = adapter.handle(event(3, "/quiz"), trace_id: "trc-telegram-e2e")
    answered = adapter.handle(event(4, "Preserve concise prompts."), trace_id: "trc-telegram-e2e")

    assert opened.handled?
    assert answered.handled?
    assert_equal "quiz_open", opened.command
    assert_equal "quiz_advance", answered.command
    assert_match "Controls: skip, done, cancel", opened.message
    entry = project.quiz_entries.last
    assert_equal "answered", entry.status
    assert_equal "Preserve concise prompts.", entry.answer
  end

  test "telegram quiz for use case creates use case quiz" do
    adapter = adapter_for_chat
    project = create_project(key: "telegram-quiz-use-case")
    adapter.instance_variable_get(:@project_ids_by_chat)[90_001] = project.id

    opened = adapter.handle(event(1, "/quiz for Billing Flow"), trace_id: "trc-telegram-e2e")

    assert opened.handled?
    assert_equal "quiz_open", opened.command
    use_case = project.use_cases.find_by!(slug: "billing-flow")
    assert_equal use_case.quiz.id, opened.api_response.dig("data", "quiz", "id")
  end

  test "telegram quiz list shows project quizzes" do
    adapter = adapter_for_chat
    project = create_project(key: "telegram-quiz-list")
    project.find_or_create_main_quiz!
    project.use_cases.create!(name: "Support").find_or_create_quiz!
    adapter.instance_variable_get(:@project_ids_by_chat)[90_001] = project.id

    listed = adapter.handle(event(1, "/quiz list"), trace_id: "trc-telegram-e2e")

    assert listed.handled?
    assert_equal "quiz_list", listed.command
    assert_match "Quizzes:", listed.message
    assert_match "project", listed.message
    assert_match "Support", listed.message
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

  def with_local_projects_root
    previous = ENV["REDWRIGHT_LOCAL_PROJECTS_ROOT"]
    Dir.mktmpdir("redwright-telegram-projects-") do |dir|
      ENV["REDWRIGHT_LOCAL_PROJECTS_ROOT"] = dir
      yield dir
    ensure
      if previous.nil?
        ENV.delete("REDWRIGHT_LOCAL_PROJECTS_ROOT")
      else
        ENV["REDWRIGHT_LOCAL_PROJECTS_ROOT"] = previous
      end
    end
  end
end
