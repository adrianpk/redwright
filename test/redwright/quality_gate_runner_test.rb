# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/quality_gate_runner"

class QualityGateRunnerTest < Minitest::Test
  def test_run_executes_lint_and_test_commands
    Dir.mktmpdir("redwright-quality-gate-ok-") do |dir|
      runner = Redwright::QualityGateRunner.new
      results = runner.run(
        project_path: dir,
        lint_command: "echo lint-ok",
        test_command: "echo test-ok"
      )

      assert_equal(2, results.size)
      assert_equal("ok", results[0].status)
      assert_equal("ok", results[1].status)
      assert_includes(results[0].stdout, "lint-ok")
      assert_includes(results[1].stdout, "test-ok")
    end
  end

  def test_run_reports_failed_command
    Dir.mktmpdir("redwright-quality-gate-fail-") do |dir|
      runner = Redwright::QualityGateRunner.new
      results = runner.run(
        project_path: dir,
        lint_command: "echo lint && exit 3",
        test_command: nil
      )

      assert_equal(1, results.size)
      assert_equal("error", results[0].status)
      assert_equal("quality_check_failed", results[0].error_message)
      assert_equal(3, results[0].exit_code)
    end
  end
end
