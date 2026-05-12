# frozen_string_literal: true

require "minitest/autorun"
require "json"
require "tmpdir"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/codex_proof/container_smoke"

class CodexProofContainerSmokeTest < Minitest::Test
  FakeStatus = Struct.new(:exitstatus) do
    def success?
      exitstatus.zero?
    end
  end

  def test_build_image_invokes_docker_build
    calls = []
    runner = lambda do |*args|
      calls << args
      ["built image", "", FakeStatus.new(0)]
    end

    result = Redwright::CodexProof::ContainerSmoke.new(
      dockerfile: "runtime/codex-proof/go/Dockerfile",
      context_dir: "runtime/codex-proof/go",
      image_name: "proof:test",
      command_runner: runner
    ).build_image

    assert_equal("built", result.fetch("status"))
    assert_equal("proof:test", result.fetch("image_name"))
    assert_equal(
      [["docker", "build", "-f", "runtime/codex-proof/go/Dockerfile", "-t", "proof:test", "runtime/codex-proof/go"]],
      calls
    )
  end

  def test_build_image_reports_failure
    runner = ->(*_args) { ["", "docker failed", FakeStatus.new(1)] }

    result = Redwright::CodexProof::ContainerSmoke.new(
      dockerfile: "Dockerfile",
      context_dir: ".",
      command_runner: runner
    ).build_image

    assert_equal("docker_build_failed", result.fetch("status"))
    assert_equal("docker failed", result.fetch("stderr"))
    assert_equal(1, result.fetch("exit_status"))
  end

  def test_run_container_mounts_packet_output_and_env
    calls = []
    runner = lambda do |*args|
      calls << args
      ["container ok", "", FakeStatus.new(0)]
    end

    result = Redwright::CodexProof::ContainerSmoke.new(
      dockerfile: "Dockerfile",
      context_dir: ".",
      image_name: "proof:test",
      command_runner: runner
    ).run_container(
      input_packet: "/tmp/packet.json",
      output_directory: "/tmp/output",
      env: { "RW_PROOF_MODE" => "smoke" }
    )

    assert_equal("container_started", result.fetch("status"))
    assert_equal("proof:test", result.fetch("image_name"))
    assert_equal("/tmp/output/smoke-result.json", result.fetch("smoke_result"))

    args = calls.fetch(0)
    assert_equal("docker", args.fetch(0))
    assert_includes(args, "run")
    assert_includes(args, "/tmp/packet.json:/redwright/input/packet.json:ro")
    assert_includes(args, "/tmp/output:/redwright/output:rw")
    assert_includes(args, "RW_PROOF_MODE=smoke")
    assert_includes(args.last, "smoke-result.json")
  end

  def test_run_container_reports_failure
    runner = ->(*_args) { ["", "run failed", FakeStatus.new(125)] }

    result = Redwright::CodexProof::ContainerSmoke.new(
      dockerfile: "Dockerfile",
      context_dir: ".",
      command_runner: runner
    ).run_container(
      input_packet: "/tmp/packet.json",
      output_directory: "/tmp/output"
    )

    assert_equal("docker_run_failed", result.fetch("status"))
    assert_equal("run failed", result.fetch("stderr"))
    assert_equal(125, result.fetch("exit_status"))
  end

  def test_clone_repository_mounts_workspace_and_writes_metadata
    calls = []
    runner = lambda do |*args|
      calls << args
      ["clone ok", "", FakeStatus.new(0)]
    end

    result = Redwright::CodexProof::ContainerSmoke.new(
      dockerfile: "Dockerfile",
      context_dir: ".",
      image_name: "proof:test",
      command_runner: runner
    ).clone_repository(
      input_packet: "/tmp/packet.json",
      output_directory: "/tmp/output",
      workspace_directory: "/tmp/workspace",
      env: { "RW_PROOF_MODE" => "clone" }
    )

    assert_equal("repository_cloned", result.fetch("status"))
    assert_equal("/tmp/output/clone-result.json", result.fetch("clone_result"))
    assert_equal("/tmp/workspace/repo", result.fetch("workspace_path"))

    args = calls.fetch(0)
    assert_equal("docker", args.fetch(0))
    assert_includes(args, "run")
    assert_includes(args, "/tmp/packet.json:/redwright/input/packet.json:ro")
    assert_includes(args, "/tmp/output:/redwright/output:rw")
    assert_includes(args, "/tmp/workspace:/redwright/workspace:rw")
    assert_includes(args, "RW_PROOF_MODE=clone")
    assert_includes(args.last, "git clone")
    assert_includes(args.last, "git checkout -B")
    assert_includes(args.last, "clone-result.json")
  end

  def test_clone_repository_reports_failure
    runner = ->(*_args) { ["", "clone failed", FakeStatus.new(128)] }

    result = Redwright::CodexProof::ContainerSmoke.new(
      dockerfile: "Dockerfile",
      context_dir: ".",
      command_runner: runner
    ).clone_repository(
      input_packet: "/tmp/packet.json",
      output_directory: "/tmp/output",
      workspace_directory: "/tmp/workspace"
    )

    assert_equal("repository_clone_failed", result.fetch("status"))
    assert_equal("clone failed", result.fetch("stderr"))
    assert_equal(128, result.fetch("exit_status"))
  end

  def test_preflight_credentials_passes_runtime_only_env
    calls = []
    runner = lambda do |*args|
      calls << args
      ["", "", FakeStatus.new(0)]
    end

    result = Redwright::CodexProof::ContainerSmoke.new(
      dockerfile: "Dockerfile",
      context_dir: ".",
      image_name: "proof:test",
      command_runner: runner
    ).preflight_credentials(
      output_directory: "/tmp/output",
      env: {
        "CODEX_API_KEY" => "codex-secret",
        "CODEBERG_PUSH_TOKEN" => "codeberg-secret"
      }
    )

    assert_equal("preflight_passed", result.fetch("status"))
    assert_equal("/tmp/output/preflight-result.json", result.fetch("preflight_result"))

    args = calls.fetch(0)
    assert_includes(args, "/tmp/output:/redwright/output:rw")
    assert_includes(args, "CODEX_API_KEY=codex-secret")
    assert_includes(args, "CODEBERG_PUSH_TOKEN=codeberg-secret")
    assert_includes(args.last, "preflight-result.json")
    assert_includes(args.last, "codex_auth_missing")
    assert_includes(args.last, "codeberg_push_auth_missing")
  end

  def test_preflight_credentials_reports_failure
    runner = ->(*_args) { ["", "missing auth", FakeStatus.new(1)] }

    result = Redwright::CodexProof::ContainerSmoke.new(
      dockerfile: "Dockerfile",
      context_dir: ".",
      command_runner: runner
    ).preflight_credentials(output_directory: "/tmp/output")

    assert_equal("preflight_failed", result.fetch("status"))
    assert_equal("missing auth", result.fetch("stderr"))
    assert_equal(1, result.fetch("exit_status"))
  end

  def test_codex_prompt_is_ticket_like_without_file_edit_instructions
    Dir.mktmpdir("codex-proof-test-") do |dir|
      packet_path = File.join(dir, "packet.json")
      File.write(packet_path, JSON.generate(valid_packet))

      prompt = Redwright::CodexProof::ContainerSmoke.new(
        dockerfile: "Dockerfile",
        context_dir: "."
      ).codex_prompt(packet_path)

      assert_includes(prompt, "normal implementation ticket")
      assert_includes(prompt, "mark-as-read")
      assert_includes(prompt, "go test ./...")
      assert_includes(prompt, "Do not commit, push")
      refute_includes(prompt, "main.go")
      refute_includes(prompt, "edit this file")
    end
  end

  def test_execute_codex_task_clones_repository_and_captures_artifacts
    Dir.mktmpdir("codex-proof-test-") do |dir|
      output = File.join(dir, "output")
      workspace = File.join(dir, "workspace")
      packet_path = File.join(dir, "packet.json")
      File.write(packet_path, JSON.generate(valid_packet))

      calls = []
      runner = lambda do |*args|
        calls << args
        ["", "", FakeStatus.new(0)]
      end

      result = Redwright::CodexProof::ContainerSmoke.new(
        dockerfile: "Dockerfile",
        context_dir: ".",
        image_name: "proof:test",
        command_runner: runner
      ).execute_codex_task(
        input_packet: packet_path,
        output_directory: output,
        workspace_directory: workspace,
        env: { "CODEX_API_KEY" => "codex-secret" },
        timeout_seconds: 30
      )

      assert_equal("codex_executed", result.fetch("status"))
      assert_equal(File.join(output, "codex-prompt.txt"), result.fetch("codex_prompt"))
      assert_equal(File.join(output, "codex-events.jsonl"), result.fetch("codex_events"))
      assert_equal(File.join(output, "codex-stderr.log"), result.fetch("codex_stderr"))
      assert_equal(File.join(output, "changed-files.txt"), result.fetch("changed_files"))
      assert_equal(File.join(output, "git-diff.patch"), result.fetch("git_diff"))
      assert_equal(File.join(output, "git-push.log"), result.fetch("git_push_log"))
      assert_equal(File.join(output, "validation-stdout.log"), result.fetch("validation_stdout"))
      assert_equal(File.join(output, "validation-stderr.log"), result.fetch("validation_stderr"))
      assert_equal(File.join(output, "result-envelope.json"), result.fetch("result_envelope"))
      assert_equal(File.join(workspace, "repo"), result.fetch("workspace_path"))
      assert(File.exist?(result.fetch("codex_prompt")))

      args = calls.fetch(0)
      assert_includes(args, "#{packet_path}:/redwright/input/packet.json:ro")
      assert_includes(args, "#{output}:/redwright/output:rw")
      assert_includes(args, "#{workspace}:/redwright/workspace:rw")
      assert_includes(args, "CODEX_API_KEY=codex-secret")
      assert_includes(args.last, "git clone")
      assert_includes(args.last, ": > /redwright/output/git-commit.log")
      assert_includes(args.last, ": > /redwright/output/git-push.log")
      assert_includes(args.last, ": > /redwright/output/validation-stdout.log")
      assert_includes(args.last, ": > /redwright/output/validation-stderr.log")
      assert_includes(args.last, "codex exec --json --color never --sandbox workspace-write")
      assert_includes(args.last, "--output-last-message /redwright/output/codex-last-message.txt")
      assert_includes(args.last, "changed-files.txt")
      assert_includes(args.last, "git-diff.patch")
      assert_includes(args.last, "validation_command")
      assert_includes(args.last, "validation-stdout.log")
      assert_includes(args.last, "validation-stderr.log")
      assert_includes(args.last, "codex_validation_failed")
      assert_includes(args.last, "codex_auth_failed")
      assert_includes(args.last, "401 Unauthorized")
      assert_includes(args.last, "git commit -m")
      assert_includes(args.last, "git push")
      assert_includes(args.last, "codex-execution-result.json")
      assert_includes(args.last, "result-envelope.json")
      assert_includes(args.last, 'backend: "codex"')
      assert_includes(args.last, "split(/\\n/)")
      assert_includes(args.last, "timeout_seconds=30")
      assert_includes(args.last, "timeout \"${timeout_seconds}s\"")
    end
  end

  def test_execute_codex_task_reads_validation_status_from_result_envelope
    Dir.mktmpdir("codex-proof-test-") do |dir|
      output = File.join(dir, "output")
      workspace = File.join(dir, "workspace")
      packet_path = File.join(dir, "packet.json")
      File.write(packet_path, JSON.generate(valid_packet))

      runner = lambda do |*_args|
        File.write(
          File.join(output, "codex-execution-result.json"),
          JSON.generate(
            "status" => "codex_validation_failed",
            "timed_out" => false,
            "validation" => {
              "status" => "failed",
              "command" => "go test ./...",
              "exit_status" => 1,
              "timed_out" => false
            }
          )
        )
        File.write(
          File.join(output, "result-envelope.json"),
          JSON.generate(
            "schema_version" => 1,
            "backend" => "codex",
            "status" => "codex_validation_failed"
          )
        )
        ["", "validation failed", FakeStatus.new(1)]
      end

      result = Redwright::CodexProof::ContainerSmoke.new(
        dockerfile: "Dockerfile",
        context_dir: ".",
        command_runner: runner
      ).execute_codex_task(
        input_packet: packet_path,
        output_directory: output,
        workspace_directory: workspace
      )

      assert_equal("codex_validation_failed", result.fetch("status"))
      assert_equal(File.join(output, "result-envelope.json"), result.fetch("result_envelope"))
      assert_equal(false, result.fetch("timed_out"))
    end
  end

  def test_execute_codex_task_reports_failure_and_timeout_state
    Dir.mktmpdir("codex-proof-test-") do |dir|
      output = File.join(dir, "output")
      workspace = File.join(dir, "workspace")
      packet_path = File.join(dir, "packet.json")
      File.write(packet_path, JSON.generate(valid_packet))

      runner = ->(*_args) { ["", "codex failed", FakeStatus.new(124)] }

      result = Redwright::CodexProof::ContainerSmoke.new(
        dockerfile: "Dockerfile",
        context_dir: ".",
        command_runner: runner
      ).execute_codex_task(
        input_packet: packet_path,
        output_directory: output,
        workspace_directory: workspace
      )

      assert_equal("codex_execution_failed", result.fetch("status"))
      assert_equal("codex failed", result.fetch("stderr"))
      assert_equal(124, result.fetch("exit_status"))
      assert_equal(true, result.fetch("timed_out"))
    end
  end

  def test_execute_codex_task_uses_structured_result_status_when_available
    Dir.mktmpdir("codex-proof-test-") do |dir|
      output = File.join(dir, "output")
      workspace = File.join(dir, "workspace")
      packet_path = File.join(dir, "packet.json")
      File.write(packet_path, JSON.generate(valid_packet))

      runner = lambda do |*_args|
        File.write(
          File.join(output, "codex-execution-result.json"),
          JSON.generate("status" => "codex_push_failed", "timed_out" => true)
        )
        ["", "push failed", FakeStatus.new(1)]
      end

      result = Redwright::CodexProof::ContainerSmoke.new(
        dockerfile: "Dockerfile",
        context_dir: ".",
        command_runner: runner
      ).execute_codex_task(
        input_packet: packet_path,
        output_directory: output,
        workspace_directory: workspace
      )

      assert_equal("codex_push_failed", result.fetch("status"))
      assert_equal(1, result.fetch("exit_status"))
      assert_equal(true, result.fetch("timed_out"))
    end
  end

  def test_codex_execution_status_distinguishes_no_diff_result
    Dir.mktmpdir("codex-proof-test-") do |dir|
      File.write(
        File.join(dir, "codex-execution-result.json"),
        JSON.generate("status" => "codex_no_diff")
      )

      status = Redwright::CodexProof::ContainerSmoke.new(
        dockerfile: "Dockerfile",
        context_dir: "."
      ).codex_execution_status(dir, FakeStatus.new(0))

      assert_equal("codex_no_diff", status)
    end
  end

  def test_codex_execution_result_tolerates_empty_json_artifact
    Dir.mktmpdir("codex-proof-test-") do |dir|
      File.write(File.join(dir, "codex-execution-result.json"), "")

      result = Redwright::CodexProof::ContainerSmoke.new(
        dockerfile: "Dockerfile",
        context_dir: "."
      ).codex_execution_result(dir)

      assert_equal({}, result)
    end
  end

  private

  def valid_packet
    {
      "schema_version" => 1,
      "repository_url" => "https://codeberg.org/adrianpk/go-todo-agent-proof.git",
      "result_branch" => "redwright/codex-proof/test-run",
      "task_prompt" => "Add a mark-as-read feature to the Go todo CLI so a user can mark an existing todo item as read, and cover the behavior with tests.",
      "validation_command" => "go test ./...",
      "output_directory" => "output",
      "remote_push_policy" => {
        "enabled" => true,
        "remote" => "origin",
        "branch" => "redwright/codex-proof/test-run"
      }
    }
  end
end
