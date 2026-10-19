require "test_helper"

class HarnessesTicketProposalIntegrationTest < ActiveSupport::TestCase
  class Adapter
    attr_reader :requests
    attr_accessor :payload, :before_result
    def initialize
      @requests = []
    end
    def call(request)
      @requests << request
      before_result&.call(request)
      Harnesses::Result.new(bytes: JSON.generate(payload))
    end
  end

  class Legacy
    attr_reader :calls
    attr_accessor :payload
    def initialize
      @calls = []
    end
    def call(execution_context:)
      @calls << execution_context
      AgentTicketExecution::LlmRequester::Result.new(ok: true,
        contract_result: AgentTicketExecution::LlmContract.new.validate(payload))
    end
  end

  setup do
    @actor = User.create!(email_address: "ticket-profile@example.test", password: "password-123")
    @profile_root = Dir.mktmpdir("ticket-profiles-")
    (@protocol_test_directories ||= []) << @profile_root
    program = File.join(@profile_root, "pi-fixture")
    FileUtils.cp(File.realpath("/bin/true"), program)
    File.write(File.join(@profile_root, "package.json"), JSON.generate(name: "@earendil-works/pi-coding-agent", version: "1.3.0"))
    auth = File.join(@profile_root, "auth.json")
    File.write(auth, "{}", perm: 0o600)
    profiles = %w[first next].map { |name| {name: name, harness: "pi", executable_ref: program,
      protocol_revision: "1.3.0", requested_provider: "fixture-provider", requested_model: "#{name}-model", credential_ref: auth,
      capabilities: {structured_output: true, os_read_only_containment: true}} }
    File.write(ENV.fetch("REDWRIGHT_HARNESS_PROFILES"), JSON.generate(version: 1, profiles: profiles), perm: 0o600)
    @adapter = Adapter.new
    @legacy = Legacy.new
  end

  test "selected proposals retain ticket context policy and host application" do
    # Inject the external completion; selection, policy, schema, application and validation remain real.
    with_agent_ticket_execution_workspace do |fixture|
      select(fixture.project, ticket_proposal_profile: "first")
      @adapter.payload = proposal(fixture)
      result = loop_for.call(request: request, ticket: fixture.ticket, workspace: workspace(fixture))
      assert result.completed?, result.to_execution.inspect
      assert_empty @legacy.calls
      call = @adapter.requests.fetch(0)
      assert_equal "pi", call.harness
      assert_equal "first-model", call.binding.fetch("requested_model")
      context = JSON.parse(call.prompt.split("Context:\n", 2).last)
      names = context.fetch("context_sections").map { |section| section.fetch("name") }
      assert_includes names, "ticket"
      assert_includes names, "relevant_files"
      refute_includes names, "dumps"
      refute_includes names, "quizzes"
      assert_includes File.read(File.join(fixture.project_path, "main.go")), "// selected proposal"
      assert_equal "completed", fixture.project.harness_operations.sole.state
    end
  end

  test "authoring selection preserves the direct API ticket default" do
    with_agent_ticket_execution_workspace do |fixture|
      select(fixture.project, authoring_profile: "first")
      @legacy.payload = proposal(fixture)
      result = loop_for.call(request: request, ticket: fixture.ticket, workspace: workspace(fixture))
      assert result.completed?, result.to_execution.inspect
      assert_equal 1, @legacy.calls.size
      assert_empty @adapter.requests
      assert_equal "direct_api", fixture.project.harness_operations.sole.binding.fetch("harness")
    end
  end

  test "unavailable selected ticket profile never invokes the legacy provider" do
    with_agent_ticket_execution_workspace do |fixture|
      select(fixture.project, ticket_proposal_profile: "first")
      File.unlink(ENV.fetch("REDWRIGHT_HARNESS_PROFILES"))
      result = loop_for.call(request: request, ticket: fixture.ticket, workspace: workspace(fixture))
      assert result.blocked?
      assert_empty @legacy.calls
      assert_empty @adapter.requests
    end
  end

  test "corrections keep one binding and record each owned base" do
    with_agent_ticket_execution_workspace do |fixture|
      select(fixture.project, ticket_proposal_profile: "first")
      @adapter.before_result = lambda do |_call|
        if @adapter.requests.size == 1
          select(fixture.project, ticket_proposal_profile: "next")
          @adapter.payload = proposal(fixture)
        else
          @adapter.payload = proposal(fixture)
          @adapter.payload["files"].first["content"] += "// accepted correction\n"
        end
      end
      result = loop_for(validation_commands: ["grep -q 'accepted correction' main.go"]).call(
        request: request, ticket: fixture.ticket, workspace: workspace(fixture))
      assert result.completed?, result.to_execution.inspect
      assert_equal 2, result.attempts
      assert_equal ["first", "first"], @adapter.requests.map { |call| call.binding.fetch("profile") }
      assert_equal 1, @adapter.requests.map(&:deadline).uniq.size
      operation = fixture.project.harness_operations.sole
      attempts = operation.attempts
      assert_equal %w[failed completed], attempts.map { |attempt| attempt.fetch("state") }
      assert_equal attempts.first.dig("evidence", "validation", "after"), attempts.last.dig("evidence", "base")
      attempts.each do |attempt|
        assert_equal operation.binding.fetch("schema_digest"), attempt.dig("evidence", "schema_digest")
        assert_equal "rails-ticket-proposal/v1", attempt.dig("evidence", "policy_revision")
        assert_equal "recorded", attempt.dig("evidence", "application", "state")
        assert_match(/\A[0-9a-f]{64}\z/, attempt.fetch("application_receipt"))
      end
      @adapter.before_result = nil
      @adapter.payload = proposal(fixture)
      following = loop_for.call(request: request.merge("request_id" => "following"), ticket: fixture.ticket, workspace: workspace(fixture))
      assert following.completed?, following.to_execution.inspect
      assert_equal "next", @adapter.requests.last.binding.fetch("profile")
    end
  end

  test "external edits conflict before proposal application" do
    with_agent_ticket_execution_workspace do |fixture|
      select(fixture.project, ticket_proposal_profile: "first")
      @adapter.payload = proposal(fixture)
      path = File.join(fixture.project_path, "main.go")
      @adapter.before_result = ->(_call) { File.write(path, "// external edit\n") }
      result = loop_for.call(request: request, ticket: fixture.ticket, workspace: workspace(fixture))
      assert result.blocked?
      assert_equal "base_conflict", result.terminal_outcome.fetch("code")
      assert_equal "// external edit\n", File.read(path)
      operation = fixture.project.harness_operations.sole
      assert_equal "failed", operation.state
      assert_nil operation.attempts.first.dig("evidence", "application")
    end
  end

  class LostApplicationReceipt < Harnesses::Operation
    def record!(lease:, evidence:)
      raise ActiveRecord::StatementInvalid, "owned receipt unavailable" if evidence.dig("application", "state") == "recorded"
      super
    end
  end

  test "uncertain application reserves capacity and prevents inference replay" do
    with_agent_ticket_execution_workspace do |fixture|
      select(fixture.project, ticket_proposal_profile: "first")
      @adapter.payload = proposal(fixture)
      result = loop_for(lifecycle: LostApplicationReceipt.new).call(request: request, ticket: fixture.ticket, workspace: workspace(fixture))
      assert result.blocked?
      assert_equal "uncertain", result.terminal_outcome.fetch("code")
      assert_includes File.read(File.join(fixture.project_path, "main.go")), "// selected proposal"
      operation = fixture.project.harness_operations.sole
      assert_equal "uncertain", operation.state
      assert_equal "pending", operation.attempts.first.dig("evidence", "application", "state")
      select(fixture.project, ticket_proposal_profile: "next")
      replay = loop_for.call(request: request, ticket: fixture.ticket, workspace: workspace(fixture))
      assert replay.blocked?
      assert_equal "uncertain", replay.terminal_outcome.fetch("code")
      assert_equal 1, @adapter.requests.size
      assert_equal "first", operation.reload.binding.fetch("profile")
      assert_equal 1, HarnessOperation.where(state: %w[running uncertain]).count
    end
  end

  private

  def select(project, **changes)
    selection = Harnesses::Selection.new(project: project)
    selection.change!(actor: @actor, request_id: SecureRandom.uuid, expected_revision: selection.current.fetch("revision"), changes: changes)
  end

  def requester(lifecycle: Harnesses::Operation.new)
    Harnesses::TicketRequester.new(legacy: @legacy, structured_call: Harnesses::StructuredCall.new(adapter: @adapter), lifecycle: lifecycle)
  end

  def loop_for(lifecycle: Harnesses::Operation.new, **options)
    AgentTicketExecution::ValidationLoop.new(context_composer: AgentTicketExecution::ContextComposer.new,
      llm_requester: requester(lifecycle: lifecycle), validation_commands: ["git diff --check"], **options)
  end

  def workspace(fixture)
    AgentTicketExecution::WorkspaceBoundary.new(allowed_projects_root: fixture.projects_root).resolve(ticket: fixture.ticket)
  end

  def request
    {"request_id" => "selected-ticket-request", "mode" => "targeted", "source_channel" => "test", "actor_identifier" => "fixture"}
  end

  def proposal(fixture)
    {"status" => "proposed_changes", "summary" => "Add selected proposal comment.",
      "files" => [{"path" => "main.go", "content" => File.read(File.join(fixture.project_path, "main.go")) + "\n// selected proposal\n"}], "commands" => []}
  end
end
