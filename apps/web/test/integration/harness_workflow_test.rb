require "test_helper"
require_relative "../support/harness_database_fixture"

class HarnessWorkflowTest < ActionDispatch::IntegrationTest
  include HarnessDatabaseFixture

  class ApiClient
    Completion = Data.define(:content, :finish_reason)
    attr_reader :calls

    def initialize(payload)
      @payload, @calls = payload, []
    end

    def configured?
      true
    end

    def complete_json(**inputs)
      @calls << inputs
      Completion.new(content: JSON.generate(@payload), finish_reason: "stop")
    end
  end

  setup do
    @user = User.create!(email_address: "workflow-operator@example.test", password: "password-123")
    @prepared = File.join(@harness_fixture_root, "prepared")
    FileUtils.mkdir_p(@prepared)
    @programs = %w[blue green].to_h { |name| [name, prepare_codex(name)] }
    profiles = @programs.map { |name, program| {name: name, harness: "codex", executable_ref: program,
      protocol_revision: "codex-exec/v1", capabilities: {structured_output: true}} }
    File.write(ENV.fetch("REDWRIGHT_HARNESS_PROFILES"), JSON.generate(version: 1, profiles: profiles), perm: 0o600)
    sign_in_as(@user)
  end

  test "web choices and owned recovery survive process changes" do
    # One owned database joins real HTTP choices, real subprocess generation and another process using the original owned lease.
    project = create_project
    choose(project, "blue", revision: 0, identity: "initial-choice")
    first = generate(project, "Initial feature")
    assert_equal "Blue feature", first.title
    assert_equal "draft", first.status
    selection = Harnesses::Selection.new(project: project)
    operation = selection.admit!(operation_key: "retained-before-switch", purpose: "specification", role: "authoring",
      schema: Specifications::Harness::OUTPUT_SCHEMA, policy_revision: "rails-authoring/v1")
    lifecycle = Harnesses::Operation.new
    lease = lifecycle.start!(operation: operation)
    outcomes = harness_processes(1) do |_index|
      client = ActionDispatch::Integration::Session.new(Rails.application)
      client.post(session_path, params: {email_address: @user.email_address, password: "password-123"})
      client.patch(project_harness_setting_path(project), params: {
        harness_setting: {authoring_profile: "green", expected_revision: 1, request_id: "other-process-choice"}
      }, as: :json)
      {"status" => client.response.status, "selection" => client.response.parsed_body}
    end
    assert_equal 200, outcomes.sole.dig("value", "status")
    assert_equal "green", outcomes.sole.dig("value", "selection", "authoring_profile")
    get project_harness_setting_path(project), as: :json
    assert_response :success
    state = response.parsed_body
    assert_equal "green", state.dig("selection", "authoring_profile")
    assert_equal "blue", state.fetch("active_bindings").sole.dig("binding", "profile")
    refute_includes response.body, lease.owner_token
    refute_includes response.body, operation.private_run_ref
    refute_includes response.body, @prepared
    following = generate(project, "Following feature")
    assert_equal "Green feature", following.title
    assert_equal "blue", operation.reload.binding.fetch("profile")
    lifecycle.finish!(lease: lease, outcome: "uncertain")
    recovered = harness_processes(1) do |_index|
      record = Harnesses::Operation.new.finish!(lease: lease, outcome: "completed")
      {"state" => record.state, "profile" => record.binding.fetch("profile")}
    end
    assert_equal({"state" => "completed", "profile" => "blue"}, recovered.sole.fetch("value"))
    get project_harness_setting_path(project), as: :json
    assert_empty response.parsed_body.fetch("active_bindings")
    choose(project, "", revision: 2, identity: "restore-default")
    get project_harness_setting_path(project), as: :json
    assert_nil response.parsed_body.dig("selection", "authoring_profile")
    assert_nil response.parsed_body.dig("selection", "ticket_proposal_profile")
  end

  test "Codex authoring reaches a validated ticket through the direct API default" do
    # The full feature path uses Codex-compatible pipes and the actual host ticket loop; only provider completion is injected.
    previous_program = ENV["REDWRIGHT_SPEC_HARNESS"]
    ENV["REDWRIGHT_SPEC_HARNESS"] = @programs.fetch("blue")
    File.write(ENV.fetch("REDWRIGHT_HARNESS_PROFILES"), JSON.generate(version: 1, profiles: []), perm: 0o600)
    with_agent_ticket_execution_workspace do |fixture|
      project = fixture.project
      document = generate(project, "Done command")
      assert_equal "draft", document.status
      post approve_document_path(document), params: {revision: document.source_hash}
      assert_redirected_to document_path(document)
      post slice_document_path(document)
      assert_redirected_to document_path(document)
      ticket = document.use_case.tickets.sole
      assert_equal "Implement done command", ticket.title
      assert_equal "approved", document.reload.status
      client = ApiClient.new({"status" => "proposed_changes", "summary" => "Implement done.",
        "files" => [{"path" => "main.go", "patch" => done_command_patch}],
        "commands" => [{"command" => "gofmt -w main.go", "purpose" => "format"}]})
      legacy = AgentTicketExecution::LlmRequester.new(request_engine: Redwright::LLM::RequestEngine.new(llm_client: client),
        model: "fixture-model", provider: "fixture-api")
      loop = AgentTicketExecution::ValidationLoop.new(context_composer: AgentTicketExecution::ContextComposer.new,
        llm_requester: Harnesses::TicketRequester.new(legacy: legacy))
      runner = AgentTicketExecution::Runner.new(
        executor: AgentTicketExecution::ValidationExecutor.new(validation_loop: loop, git_finalizer: AgentTicketExecution::GitFinalizer.new),
        workspace_boundary: AgentTicketExecution::WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root))
      outcome = runner.call(request: {"request_id" => "feature-to-ticket", "mode" => "targeted", "ticket_ref" => ticket.display_key,
        "board_id" => fixture.board.id, "admin_assignee" => nil}).execution
      assert_equal "completed", outcome.fetch("state"), outcome.inspect
      assert_equal "ready_for_review", outcome.dig("terminal_outcome", "status")
      assert_equal "reviewing", ticket.reload.workflow_status
      assert_equal "committed", outcome.dig("details", "git", "code")
      assert outcome.dig("details", "validation_results").all? { |result| result.fetch("status") == "ok" }
      assert_equal 1, client.calls.size
      sections = JSON.parse(client.calls.sole.fetch(:user_text)).fetch("context_sections").map { |section| section.fetch("name") }
      assert_includes sections, "ticket"
      refute_includes sections, "dumps"
      assert_equal ["codex", "codex", "direct_api"], project.harness_operations.order(:id).map { |operation| operation.binding.fetch("harness") }
      assert project.harness_operations.all? { |operation| operation.state == "completed" }
      assert_empty AgentTicketExecutionWorkspaceFixture.run_git!("remote", fixture.project_path).strip
    end
  ensure
    ENV["REDWRIGHT_SPEC_HARNESS"] = previous_program
  end

  private

  def choose(project, profile, revision:, identity:)
    patch project_harness_setting_path(project), params: {
      harness_setting: {authoring_profile: profile, expected_revision: revision, request_id: identity}
    }, as: :json
    assert_response :success
  end

  def generate(project, name)
    feature = create_use_case(project: project, name: name)
    post generate_documents_path(project_id: project.id), params: {feature: name, use_case_id: feature.id}
    document = feature.reload.specification
    assert document, response.body
    assert_redirected_to document_path(document)
    document
  end

  def prepare_codex(name)
    path = File.join(@prepared, "#{name}-codex")
    source = <<~'SCRIPT'
      #!/usr/bin/env ruby
      require "json"
      context = JSON.parse(STDIN.read.split("Context:\n", 2).last)
      title = File.basename(__FILE__).split("-").first.capitalize + " feature"
      value = if context.key?("existing_tickets")
        {tickets: [{key: nil, title: "Implement done command", body: "Implement done <task-number>, preserve other tasks and pass go test ./..."}]}
      else
        {title: title, body: "Implement the bounded feature and validate its behavior."}
      end
      File.write(ARGV.fetch(ARGV.index("--output-last-message") + 1), JSON.generate(value))
    SCRIPT
    File.write(path, source, perm: 0o700)
    path
  end
end
