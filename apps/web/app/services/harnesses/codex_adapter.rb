require "json"
require "tmpdir"

module Harnesses
  class CodexAdapter
    def initialize(supervisor: ProcessSupervisor.new)
      @supervisor = supervisor
    end

    def call(request)
      Dir.mktmpdir("redwright-spec-generation-") do |directory|
        schema = File.join(directory, "schema.json")
        output = File.join(directory, "result.json")
        File.write(schema, JSON.generate(request.schema))
        command = [request.program, "exec", "--sandbox", "read-only", "--ephemeral", "--skip-git-repo-check", "--color", "never",
          "-c", 'approval_policy="never"', "--output-schema", schema, "--output-last-message", output, "-"]
        execution = @supervisor.run(command: command, workspace: request.workspace, deadline: request.deadline,
          input: request.prompt, cancellation: request.cancellation)
        unless execution.status.success? && File.file?(output)
          raise Error.new("Structured generation failed.", code: :failed, diagnostics: execution.diagnostics)
        end
        bytes = File.binread(output, request.max_output_bytes + 1)
        raise Error.new("The harness result is too large.", code: :output_too_large) if bytes.bytesize > request.max_output_bytes
        Result.new(bytes: bytes, diagnostics: execution.diagnostics)
      end
    rescue Errno::ENOENT, Errno::EACCES
      raise Error.new("The local Codex harness is unavailable.", code: :unavailable)
    end
  end
end
