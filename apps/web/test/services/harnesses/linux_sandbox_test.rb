require "test_helper"

class HarnessesLinuxSandboxTest < ActiveSupport::TestCase
  test "the OS enforces the declared writable boundary" do
    # A native shell actively attempts writes under the exact containment policy, without model cooperation.
    project = create_project
    outside = create_project(key: "outside")
    sentinel = File.join(outside.root_path, "sentinel")
    File.write(sentinel, "unchanged")
    File.write(File.join(project.root_path, "host-only"), "unrelated workspace resource")
    request = sandbox_request(project.root_path)
    scratch = nil
    Harnesses::LinuxSandbox.new.with_context(request) do |context|
      scratch = context.scratch
      assert context.verified?
      assert_equal "pi-linux-bwrap/v1", context.policy_revision
      script = 'set -eu; printf owned > /scratch/result; if (: > /workspace/forbidden) 2>/dev/null; then exit 7; fi; if (: > "$1") 2>/dev/null; then exit 8; fi; test ! -e /workspace/host-only; test ! -e /run/user; test ! -e /var/run/docker.sock; test ! -e /home; test -z "${UNRELATED_FIXTURE_SECRET:-}"; printf admitted'
      result = run_in(context, request, ["/bin/sh", "-c", script, "fixture", sentinel])
      assert result.status.success?
      assert_equal "admitted", result.stdout
      assert_equal "owned", File.read(File.join(scratch, "result"))
      assert_equal 0o700, File.stat(scratch).mode & 0o777
      assert_not File.exist?(File.join(project.root_path, "forbidden"))
      assert_equal "unchanged", File.read(sentinel)
      mounts = context.command_for(["/bin/sh", "-c", "exit"])
      assert_includes mounts, "--unshare-ipc"
      assert_includes mounts, "--unshare-pid"
      assert_not_includes mounts, "--ro-bind-try"
      assert_not_includes mounts, Dir.home
      assert_not_includes mounts, "/usr/lib"
      assert_not_includes mounts, project.root_path
    end
    assert_not File.exist?(scratch)
  end

  test "unrelated descriptors are closed before execution" do
    # An explicitly inheritable host file descriptor must not enter the sandbox process.
    project = create_project
    request = sandbox_request(project.root_path)
    File.open(File.join(project.root_path, "private"), "w") do |file|
      file.close_on_exec = false
      Harnesses::LinuxSandbox.new.with_context(request) do |context|
        result = run_in(context, request, ["/bin/sh", "-c", "test ! -e /proc/self/fd/#{file.fileno}; printf closed"])
        assert result.status.success?
        assert_equal "closed", result.stdout
      end
    end
  end

  test "exceptional cleanup removes only the owned scratch" do
    # Context failures remove their private runtime tree after child cleanup; a neighboring file remains intact.
    project = create_project
    request = sandbox_request(project.root_path)
    scratch = nil
    assert_raises(Harnesses::Error) do
      Harnesses::LinuxSandbox.new.with_context(request) do |context|
        scratch = context.scratch
        raise Harnesses::Error.new("Owned fixture failure.", code: :failed)
      end
    end
    assert_not File.exist?(scratch)
    assert File.directory?(project.root_path)
  end

  test "unsupported platforms and launchers fail before execution" do
    # Missing containment support has an explicit outcome and never falls back to an uncontained command.
    project = create_project
    launcher = File.join(project.root_path, "launcher")
    File.write(launcher, "#!/bin/sh\nexit 0\n")
    File.chmod(0o700, launcher)
    cases = {
      "macOS" => [{program: "/bin/sh", platform: "arm64-darwin"}, :unsupported_platform],
      "launcher" => [{program: launcher}, :unsupported_executable],
      "missing tool" => [{program: "/bin/sh", bwrap: "/nonexistent/bwrap"}, :containment_unavailable]
    }
    cases.each do |name, (arguments, code)|
      error = assert_raises(Harnesses::Error, name) { Harnesses::LinuxSandbox.ready!(**arguments) }
      assert_equal code, error.code
    end
  end

  test "a failed namespace probe cannot admit a context" do
    # A failed tool cannot manufacture readiness or leave temporary runtime state behind.
    project = create_project
    error = assert_raises(Harnesses::Error) do
      Harnesses::LinuxSandbox.new(bwrap: "/bin/false").with_context(sandbox_request(project.root_path)) { flunk "admitted" }
    end
    assert_equal :containment_unavailable, error.code
  end

  private

  def sandbox_request(root)
    Harnesses::Request.new(instructions: "Owned boundary fixture.", context: {}, workspace: root,
      schema: {}, purpose: "specification", program: "/bin/sh", timeout: 10)
  end

  def run_in(context, request, command)
    Harnesses::ProcessSupervisor.new.run(command: context.command_for(command), workspace: context.workspace,
      env: context.environment, unsetenv_others: true, deadline: request.deadline, capture_stdout: 4096)
  end
end
