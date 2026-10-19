require "test_helper"
require "rbconfig"
require "timeout"

class HarnessesProcessSupervisorTest < ActiveSupport::TestCase
  test "pipes drain while large input is written" do
    # Both output pipes fill before stdin is read, exposing blocking write/read ordering.
    source = <<~'RUBY'
      STDOUT.binmode
      STDERR.binmode
      STDOUT.write("o" * 131072)
      STDERR.write("s" * 131072)
      input = STDIN.read
      exit 8 unless input == "i" * 262144
      STDOUT.write("done")
    RUBY
    output = "".b
    result = supervise(source, input: "i" * 262144) { |_session, chunk| output << chunk }
    assert result.status.success?
    assert_equal "o" * 131072 + "done", output
    assert_equal 131072, result.diagnostics.fetch("stderr").fetch("bytes")
    assert_equal 0, result.diagnostics.fetch("stderr").fetch("retained_bytes")
    assert_empty result.stdout
  end

  test "stream ceilings fail without leaking content" do
    # Tiny fixture limits establish the same aggregate guards used by production limits.
    {"stdout" => "STDOUT", "stderr" => "STDERR"}.each do |stream, constant|
      supervisor = Harnesses::ProcessSupervisor.new(stdout_limit: 1024, stderr_limit: 1024)
      error = assert_raises(Harnesses::Error) { supervise("#{constant}.write('private fixture data' * 1024)", supervisor: supervisor) }
      assert_equal :stream_limit, error.code
      assert_operator error.diagnostics.fetch(stream).fetch("bytes"), :>, 1024
      assert_not_includes error.message + error.diagnostics.to_json, "private fixture data"
    end
  end

  test "cancellation and timeout reap the owned child" do
    # The PID marker proves launch before cancellation, and an independent child survives cleanup.
    project = create_project
    marker = File.join(project.root_path, "owned-pid")
    other_pid = Process.spawn("sleep", "30", pgroup: true)
    source = "File.write(#{marker.dump}, Process.pid.to_s); sleep 30"
    error = assert_raises(Harnesses::Error) { supervise(source, cancellation: -> { File.exist?(marker) }) }
    assert_equal :cancelled, error.code
    owned_pid = Integer(File.read(marker))
    assert_raises(Errno::ESRCH) { Process.kill(0, owned_pid) }
    assert_raises(Errno::ECHILD) { Process.waitpid(owned_pid, Process::WNOHANG) }
    assert_equal 1, Process.kill(0, other_pid)
    error = assert_raises(Harnesses::Error) { supervise("sleep 30", timeout: 0.05) }
    assert_equal :timed_out, error.code
  ensure
    if other_pid
      Process.kill("KILL", other_pid)
      Process.wait(other_pid)
    end
  end

  test "an exited leader cannot leave an owned pipe hanging" do
    # Keep the leader unreaped until an inherited pipe is closed by group cleanup.
    project = create_project
    marker = File.join(project.root_path, "descendant-pid")
    error = assert_raises(Harnesses::Error) do
      Harnesses::ProcessSupervisor.new.run(command: ["/bin/sh", "-c", 'sleep 30 & printf "%s" "$!" > "$1"; exit 0', "owned-fixture", marker],
        workspace: project.root_path, deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 0.2)
    end
    assert_equal :timed_out, error.code
    child_pid = Integer(File.read(marker))
    # An orphan can briefly remain as a zombie until the host init reaps it.
    stopped = Timeout.timeout(1) do
      loop do
        stat = File.exist?("/proc/#{child_pid}/stat") ? File.read("/proc/#{child_pid}/stat") : nil
        break true if stat.nil? || stat.split[2] == "Z"
        IO.select(nil, nil, nil, 0.005)
      rescue Errno::ENOENT, Errno::ESRCH
        break true
      end
    end
    assert stopped
  end

  private

  def supervise(source, supervisor: Harnesses::ProcessSupervisor.new, timeout: 2, **options, &block)
    supervisor.run(command: [RbConfig.ruby, "-e", source], workspace: Dir.tmpdir,
      deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout, env: {"RUBYOPT" => nil}, **options, &block)
  end
end
