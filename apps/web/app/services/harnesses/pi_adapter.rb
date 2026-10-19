module Harnesses
  class PiAdapter
    VERSION = "1.3.0".freeze
    FLAGS = %w[--mode rpc --no-session --no-tools --no-extensions --no-mcp --no-skills --no-prompt-templates --no-themes --no-context-files --no-approve --offline].freeze

    def initialize(supervisor: ProcessSupervisor.new, sandbox: LinuxSandbox.new)
      @supervisor, @sandbox = supervisor, sandbox
    end

    def call(request)
      unless @sandbox
        raise Error.new("Pi requires a verified containment policy before invocation.", code: :unsupported_capability)
      end
      validate_binding!(request)
      @sandbox.with_context(request) do |context|
        unless context.verified? && context.policy_revision.is_a?(String) && context.policy_revision.bytesize.between?(1, 128)
          raise Error.new("Pi containment evidence is unavailable.", code: :unsupported_capability)
        end
        version = ProcessSupervisor.new(stdout_limit: 4096, stderr_limit: 4096).run(
          command: context.command_for([request.program, "--version"]), workspace: context.workspace,
          env: context.environment, unsetenv_others: true, deadline: request.deadline, capture_stdout: 4096,
          cancellation: request.cancellation)
        unless version.status.success? && version.stdout.strip == VERSION
          raise Error.new("The Pi adapter requires version 1.3.0.", code: :unsupported_version)
        end
        binding = request.binding
        command = [request.program, *FLAGS, "--provider", binding.fetch("requested_provider"), "--model", binding.fetch("requested_model")]
        command += ["--thinking", binding["thinking"]] if binding["thinking"]
        protocol = PiProtocol.new(request)
        execution = @supervisor.run(command: context.command_for(command), workspace: context.workspace,
          env: context.environment, unsetenv_others: true, deadline: request.deadline, keep_input: true,
          cancellation: request.cancellation, on_start: ->(input) { protocol.start(input) }) do |input, chunk|
          protocol.feed(input, chunk)
        end
        raise Error.new("The Pi process did not exit successfully.", code: :failed, diagnostics: execution.diagnostics) unless execution.status.success?
        protocol.finish.with(diagnostics: execution.diagnostics.merge("containment_policy_revision" => context.policy_revision))
      end
    end

    private

    def validate_binding!(request)
      value = request.binding
      unless request.harness == "pi" && value.is_a?(Hash) && value["harness"] == "pi" && value["protocol_revision"] == VERSION &&
          %w[requested_provider requested_model].all? { |key| value[key].is_a?(String) && value[key].bytesize.between?(1, 128) } &&
          (value["thinking"].nil? || PiProtocol::THINKING_LEVELS.include?(value["thinking"])) &&
          value["schema_digest"] == CanonicalJson.digest(request.schema)
        raise Error.new("The retained Pi selection is incomplete or incompatible.", code: :invalid_binding)
      end
      message = request.prompt + "\nOutput JSON Schema:\n" + JSON.generate(request.schema)
      # Include JSON escaping and all setup records in the encoded request allowance.
      if JSON.generate({type: "prompt", message: message}).bytesize + 4096 > ProcessSupervisor::MAX_STDIN_BYTES
        raise Error.new("Encoded Pi input is too large.", code: :request_too_large)
      end
    end
  end
end
