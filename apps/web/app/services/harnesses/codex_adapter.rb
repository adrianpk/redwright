require "json"
require "tmpdir"
require "timeout"

module Harnesses
  class CodexAdapter
    def call(request)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + request.timeout
      Dir.mktmpdir("redwright-spec-generation-") do |directory|
        schema = File.join(directory, "schema.json")
        prompt = File.join(directory, "prompt.txt")
        output = File.join(directory, "result.json")
        File.write(schema, JSON.generate(request.schema))
        File.write(prompt, request.prompt)
        command = [request.program, "exec", "--sandbox", "read-only", "--ephemeral", "--skip-git-repo-check", "--color", "never",
          "-c", 'approval_policy="never"', "--output-schema", schema, "--output-last-message", output, "-"]
        status = run(command, prompt, request.workspace, deadline)
        unless status.success? && File.file?(output)
          raise Error.new("Structured generation failed.", code: :failed)
        end
        bytes = File.binread(output, request.max_output_bytes + 1)
        raise Error.new("The harness result is too large.", code: :output_too_large) if bytes.bytesize > request.max_output_bytes
        Result.new(bytes: bytes)
      end
    rescue Errno::ENOENT, Errno::EACCES
      raise Error.new("The local Codex harness is unavailable.", code: :unavailable)
    end

    private

    def run(command, prompt, workspace, deadline)
      remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
      raise Error.new("Structured generation timed out.", code: :timed_out) unless remaining.positive?
      pid = Process.spawn(*command, in: prompt, out: File::NULL, err: File::NULL, chdir: workspace, pgroup: true, close_others: true)
      begin
        _, status = Timeout.timeout(remaining) { Process.wait2(pid) }
        status
      rescue Timeout::Error
        begin
          Process.kill("KILL", -pid)
        rescue Errno::ESRCH
          # The owned process may have exited at the deadline.
        end
        Process.wait(pid)
        raise Error.new("Structured generation timed out.", code: :timed_out)
      end
    end
  end
end
