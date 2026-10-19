module Harnesses
  class ProcessSupervisor
    MAX_STDIN_BYTES = 1024 * 1024
    MAX_STDOUT_BYTES = 64 * 1024 * 1024
    MAX_STDERR_BYTES = 2 * 1024 * 1024
    MAX_DIAGNOSTIC_BYTES = 256 * 1024
    POLL_SECONDS = 0.02
    Outcome = Data.define(:status, :stdout, :diagnostics)

    class Input
      def initialize(pipe, limit)
        @pipe, @limit, @written = pipe, limit, 0
        @pending = "".b
        @closing = false
      end

      def write(bytes)
        raise Error.new("Harness input is already closed.", code: :protocol_error) if @closing
        @written += bytes.bytesize
        raise Error.new("Encoded harness input is too large.", code: :request_too_large) if @written > @limit
        @pending << bytes.b
      end

      def close
        @closing = true
        flush_close
      end

      def writable
        @pipe if !@pipe.closed? && !@pending.empty?
      end

      def flush
        written = @pipe.write_nonblock(@pending, exception: false)
        @pending = @pending.byteslice(written..) if written.is_a?(Integer)
        flush_close
      end

      private

      def flush_close
        @pipe.close if @closing && @pending.empty? && !@pipe.closed?
      end
    end

    def initialize(stdout_limit: MAX_STDOUT_BYTES, stderr_limit: MAX_STDERR_BYTES)
      unless stdout_limit.is_a?(Integer) && stdout_limit.between?(1, MAX_STDOUT_BYTES) &&
          stderr_limit.is_a?(Integer) && stderr_limit.between?(1, MAX_STDERR_BYTES)
        raise ArgumentError, "Invalid harness stream limits"
      end
      @stdout_limit, @stderr_limit = stdout_limit, stderr_limit
    end

    def run(command:, workspace:, deadline:, input: nil, keep_input: false, env: {}, unsetenv_others: false,
      capture_stdout: 0, cancellation: nil, on_start: nil, &on_stdout)
      unless capture_stdout.is_a?(Integer) && capture_stdout.between?(0, MAX_DIAGNOSTIC_BYTES)
        raise ArgumentError, "Invalid harness capture limit"
      end
      totals = {"stdout" => 0, "stderr" => 0}
      captured = "".b
      reaped = false
      check_lifetime!(deadline, cancellation)
      stdin_read, stdin_write = IO.pipe
      stdout_read, stdout_write = IO.pipe
      stderr_read, stderr_write = IO.pipe
      pid = Process.spawn(env, *command, in: stdin_read, out: stdout_write, err: stderr_write,
        chdir: workspace, pgroup: true, close_others: true, unsetenv_others: unsetenv_others)
      [stdin_read, stdout_write, stderr_write].each(&:close)
      session = Input.new(stdin_write, MAX_STDIN_BYTES)
      session.write(input) if input
      on_start&.call(session)
      session.close unless keep_input
      streams = {stdout_read => "stdout", stderr_read => "stderr"}
      loop do
        check_lifetime!(deadline, cancellation)
        if streams.empty?
          waited = Process.waitpid2(pid, Process::WNOHANG)
          if waited
            reaped = true
            return Outcome.new(status: waited.last, stdout: captured.freeze, diagnostics: diagnostics(totals))
          end
        end
        ready = IO.select(streams.keys, [session.writable].compact, nil,
          [POLL_SECONDS, deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)].min.clamp(0, POLL_SECONDS))
        next unless ready
        ready.first.each do |pipe|
          chunk = pipe.read_nonblock(16 * 1024, exception: false)
          if chunk.nil?
            streams.delete(pipe)
            pipe.close
          elsif chunk.is_a?(String)
            stream = streams.fetch(pipe)
            totals[stream] += chunk.bytesize
            limit = stream == "stdout" ? @stdout_limit : @stderr_limit
            raise Error.new("The harness exceeded its #{stream} byte limit.", code: :stream_limit) if totals[stream] > limit
            if stream == "stdout"
              remaining = capture_stdout - captured.bytesize
              captured << chunk.byteslice(0, remaining) if remaining.positive?
              on_stdout&.call(session, chunk)
            end
          end
        end
        session.flush if ready[1].any?
      end
    rescue Error => error
      raise Error.new(error.message, code: error.code, diagnostics: diagnostics(totals || {}))
    rescue Errno::ENOENT, Errno::EACCES
      raise Error.new("The local harness executable or workspace is unavailable.", code: :unavailable)
    rescue Errno::EPIPE
      raise Error.new("The harness closed its input before completing the request.", code: :failed, diagnostics: diagnostics(totals))
    ensure
      [stdin_read, stdin_write, stdout_read, stdout_write, stderr_read, stderr_write].compact.each { |pipe| pipe.close unless pipe.closed? }
      if pid && !reaped
        # Keep the leader unreaped until termination so its process-group identity
        # cannot be reused while an owned descendant still holds a pipe open.
        begin
          Process.kill("KILL", -pid)
        rescue Errno::ESRCH
          # The owned group may already have exited.
        end
        Process.waitpid(pid)
      end
    end

    private

    def check_lifetime!(deadline, cancellation)
      raise Error.new("The harness call was cancelled.", code: :cancelled) if cancellation&.call
      if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
        raise Error.new("The harness call timed out.", code: :timed_out)
      end
    end

    def diagnostics(totals)
      # Raw streams may contain credentials, prompts or model output. Retain only
      # byte counts, rather than attempting to identify every possible secret.
      totals.transform_values { |bytes| {"bytes" => bytes, "retained_bytes" => 0} }
    end
  end
end
