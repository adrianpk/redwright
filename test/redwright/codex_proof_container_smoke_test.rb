# frozen_string_literal: true

require "minitest/autorun"

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
end
