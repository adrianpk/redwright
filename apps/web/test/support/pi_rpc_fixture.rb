require "rbconfig"

module PiRpcFixture
  class Sandbox
    Context = Data.define(:workspace, :environment) do
      # This context admits only the owned protocol fixture, not the real Pi binary.
      def verified? = true
      def policy_revision = "owned-pipe-fixture/v1"
      def command_for(command) = command
    end

    def initialize(root, scenario)
      @root, @scenario = root, scenario
    end

    def with_context(request)
      environment = {"PATH" => ENV.fetch("PATH"), "FIXTURE_SCENARIO" => @scenario, "FIXTURE_ROOT" => @root}
      yield Context.new(workspace: request.workspace, environment: environment)
    ensure
      File.write(File.join(@root, "cleaned"), "done")
    end
  end

  def pi_request(root, scenario: "valid", schema: Specifications::Harness::OUTPUT_SCHEMA, timeout: 5, **options)
    program = File.join(root, "pi-fixture")
    File.write(program, "#!#{RbConfig.ruby}\n" + File.read(File.expand_path("fixtures/pi_rpc.rb", __dir__)))
    File.chmod(0o700, program)
    binding = {"harness" => "pi", "protocol_revision" => "1.3.0", "requested_provider" => "fixture-provider",
      "requested_model" => "fixture-model", "schema_digest" => Harnesses::CanonicalJson.digest(schema), "thinking" => "low"}
    request = Harnesses::Request.new(instructions: "Write bounded behavior.", context: {note: "source material"},
      workspace: root, schema: schema, purpose: "specification", program: program, harness: "pi", binding: binding,
      timeout: timeout, **options)
    adapter = Harnesses::PiAdapter.new(sandbox: Sandbox.new(root, scenario))
    [request, adapter]
  end
end
