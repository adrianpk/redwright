require "test_helper"

class HarnessesAuthoringIntegrationTest < ActiveSupport::TestCase
  class Adapter
    attr_reader :requests
    attr_accessor :before_result, :output

    def initialize
      @requests = []
    end

    def call(request)
      @requests << request
      before_result&.call(request)
      context = JSON.parse(request.prompt.split("Context:\n", 2).last)
      value = output || case request.purpose
      when "slicing" then {"tickets" => [{"key" => nil, "title" => "Bounded work", "body" => "Implement the approved behavior."}]}
      when "references" then references(context)
      else {"title" => "Selected output", "body" => "Bounded selected behavior."}
      end
      Harnesses::Result.new(bytes: JSON.generate(value), observed_provider: "fixture-provider", observed_model: request.binding.fetch("requested_model"))
    end

    private

    def references(context)
      body = context.fetch("index_body")
      documents = if context["operation"] == "sync"
        removed = context.fetch("removed_paths", [])
        body = body.lines.reject { |line| removed.include?(line[/`([^`]+)`/, 1]) }.join
        context.fetch("documents")
      else
        body = body.lines.reject { |line| line.include?("`#{context['old_path'] || context['path']}`") }.join
        context["operation"] == "delete" ? [] : [context.slice("path", "description")]
      end
      documents.each do |document|
        description = document.fetch("description") { document["body"].to_s.lines.first.to_s.delete_prefix("# ").strip }
        body += "\n\n- `#{document.fetch('path')}`"
        body += " — #{description}" unless description.empty?
        body += "\n"
      end
      {"body" => body}
    end
  end

  setup do
    @project = create_project
    create_board(project: @project).columns.create!(key: "backlog", title: "Ready", position: 0)
    @actor = User.create!(email_address: "harness-author@example.test", password: "password-123")
    @root = Dir.mktmpdir("selected-authoring-")
    @protocol_test_directories << @root
    program = File.join(@root, "native-fixture")
    FileUtils.cp(File.realpath("/bin/true"), program)
    File.write(File.join(@root, "package.json"), JSON.generate(name: "@earendil-works/pi-coding-agent", version: "1.3.0"))
    credential = File.join(@root, "auth.json")
    File.write(credential, "{}", perm: 0o600)
    profiles = %w[first next].map { |name| {name: name, harness: "pi", executable_ref: program,
      protocol_revision: "1.3.0", requested_provider: "fixture-provider", requested_model: "#{name}-model", credential_ref: credential,
      capabilities: {structured_output: true, os_read_only_containment: true}} }
    File.write(ENV.fetch("REDWRIGHT_HARNESS_PROFILES"), JSON.generate(version: 1, profiles: profiles), perm: 0o600)
    @selection = Harnesses::Selection.new(project: @project)
    @selection.change!(actor: @actor, request_id: "choose-first", expected_revision: 0, changes: {authoring_profile: "first"})
    @adapter = Adapter.new
    adapter = @adapter
    @authoring = Object.new
    @authoring.define_singleton_method(:new) do |**options|
      Harnesses::Authoring.new(**options, structured_call: Harnesses::StructuredCall.new(adapter: adapter))
    end
  end

  test "all four authoring owners use the selected Pi binding" do
    # Inject only the external result boundary; real admission, schema/domain validation and file stores remain active.
    use_case = create_use_case(project: @project)
    spec = Specifications::Generator.new(project: @project, use_case: use_case, authoring: @authoring).call
    assert_equal "draft", spec.status
    spec.approve!(revision: spec.source_hash)
    Specifications::Slicing.new(specification: spec, authoring: @authoring).call
    dump = @project.dumps.create!(body: "Original notes", status: "ready")
    Dumps::Documents.new(@project, authoring: @authoring).curate(dump, revision: dump.source_hash)
    assert_equal "ready", dump.reload.status
    store = @project.protocol_files
    store.create("AGENTS.md", "# Rules\n")
    created = ProjectProtocols::Documents.new(store: store, authoring: @authoring).create(name: "care", body: "Preserve authority.")
    assert_equal "Preserve authority.", created.body
    assert_equal %w[specification slicing curation references], @adapter.requests.map(&:purpose)
    @adapter.requests.each do |request|
      assert_equal "pi", request.harness
      assert_equal "first", request.binding.fetch("profile")
      assert_equal "pi-linux-bwrap/v1", request.binding.fetch("containment_policy_revision")
      assert_equal Harnesses::CanonicalJson.digest(request.schema), request.binding.fetch("schema_digest")
    end
    assert_equal 4, @project.harness_operations.count
    @project.harness_operations.each do |operation|
      assert_equal "completed", operation.state
      assert_equal 1, operation.attempts.size
      assert_match(/\A[0-9a-f]{64}\z/, operation.attempts.last.fetch("output_digest"))
    end
  end

  test "nested calls retain one binding after a default change" do
    # Protocol batches can make multiple calls; only the following independent action sees a new selection.
    @adapter.before_result = ->(_request) {
      @selection.change!(actor: @actor, request_id: "choose-next", expected_revision: 1, changes: {authoring_profile: "next"}) if @adapter.requests.size == 1
    }
    store = @project.protocol_files
    store.create("AGENTS.md", "# Rules\n")
    ProjectProtocols::Documents.new(store: store, authoring: @authoring).create(name: "verify", collection: "playbooks", body: "Check the behavior.")
    assert_operator @adapter.requests.size, :>=, 2
    assert_equal ["first"], @adapter.requests.map { |request| request.binding.fetch("profile") }.uniq
    assert_equal 1, @adapter.requests.map { |request| request.binding.fetch("operation_id") }.uniq.size
    assert_equal 1, @adapter.requests.map(&:deadline).uniq.size
    assert_equal 1, @project.harness_operations.count
    use_case = create_use_case(project: @project)
    Specifications::Generator.new(project: @project, use_case: use_case, authoring: @authoring).call
    assert_equal "next", @adapter.requests.last.binding.fetch("profile")
    assert_equal 2, @project.harness_operations.count
  end

  test "domain rejection preserves the file and fails the operation" do
    # A schema-valid response still cannot change an approved artifact when its domain values are blank.
    spec = create_document(project: @project, status: "approved")
    original = spec.source
    @adapter.output = {"title" => "Changed", "body" => " "}
    assert_raises(Specifications::Error) { Specifications::Generator.new(project: @project, use_case: spec.use_case, authoring: @authoring).call }
    assert_equal original, spec.source
    assert_equal "approved", spec.reload.status
    assert_equal "failed", @project.harness_operations.sole.state
  end

  test "a missing selected profile never falls back" do
    # Readiness is rechecked for new admission without touching the previous approved file or invoking the adapter.
    spec = create_document(project: @project, status: "approved")
    original = spec.source
    File.write(ENV.fetch("REDWRIGHT_HARNESS_PROFILES"), JSON.generate(version: 1, profiles: []), perm: 0o600)
    error = assert_raises(Specifications::Error) {
      Specifications::Generator.new(project: @project, use_case: spec.use_case, authoring: @authoring).call
    }
    assert_equal :unknown_profile, error.code
    assert_empty @adapter.requests
    assert_equal original, spec.source
    assert_equal "approved", spec.reload.status
  end

  test "body edits remain independent of harness readiness" do
    # Lazy admission preserves ordinary file editing even when the configured authoring profile is unavailable.
    File.write(ENV.fetch("REDWRIGHT_HARNESS_PROFILES"), JSON.generate(version: 1, profiles: []), perm: 0o600)
    store = @project.protocol_files
    store.create("AGENTS.md", "# Rules\n")
    store.create(".agents/CARE.md", "# Original\n")
    document = store.find_path(".agents/CARE.md")
    ProjectProtocols::Documents.new(store: store, authoring: @authoring).update(document, body: "# Revised\n", revision: document.revision)
    assert_equal "# Revised\n", document.body
    assert_empty @adapter.requests
    assert_equal 0, @project.harness_operations.count
  end

  test "finalization uncertainty retains capacity without replay" do
    # Once publication returns, a failed durable completion must not repeat inference or pretend the call is safely terminal.
    adapter = @adapter
    lifecycle = Class.new(Harnesses::Operation) do
      def finish!(**options)
        raise ActiveRecord::ConnectionNotEstablished, "Owned finalization fixture" if options.fetch(:outcome) == "completed"
        super
      end
    end.new
    factory = Object.new
    factory.define_singleton_method(:new) do |**options|
      Harnesses::Authoring.new(**options, lifecycle: lifecycle, structured_call: Harnesses::StructuredCall.new(adapter: adapter))
    end
    use_case = create_use_case(project: @project)
    assert_raises(ActiveRecord::ConnectionNotEstablished) {
      Specifications::Generator.new(project: @project, use_case: use_case, authoring: factory).call
    }
    assert_equal "draft", use_case.reload.specification.status
    assert_equal 1, @adapter.requests.size
    operation = @project.harness_operations.sole
    assert_equal "uncertain", operation.state
    assert_equal 1, operation.attempts.size
    assert_nil operation.finished_at
  end
end
