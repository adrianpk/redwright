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
end
