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

  private

  def select(project, **changes)
    selection = Harnesses::Selection.new(project: project)
    selection.change!(actor: @actor, request_id: SecureRandom.uuid, expected_revision: selection.current.fetch("revision"), changes: changes)
  end

  def requester(lifecycle: Harnesses::Operation.new)
    Harnesses::TicketRequester.new(legacy: @legacy, structured_call: Harnesses::StructuredCall.new(adapter: @adapter), lifecycle: lifecycle)
  end

  def loop_for(**options)
    AgentTicketExecution::ValidationLoop.new(context_composer: AgentTicketExecution::ContextComposer.new,
      llm_requester: requester, validation_commands: ["git diff --check"], **options)
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
