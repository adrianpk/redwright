# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap_minimum_gate"

class BootstrapMinimumGateTest < Minitest::Test
  def test_blocks_project_name_gap_for_ruby_fixture
    gate = Redwright::BootstrapMinimumGate.new
    result = gate.evaluate(
      intent: "change",
      actions: [{ "type" => "write_file", "args" => {} }],
      gaps: [
        { "id" => "g1", "field" => "project_name", "question" => "Project name?", "resolved" => false, "priority" => 1 }
      ]
    )

    assert_equal(1, result[:technical_blocking_gaps].size)
    assert_equal(0, result[:alignment_optional_gaps].size)
  end

  def test_blocks_module_name_gap_for_go_fixture
    gate = Redwright::BootstrapMinimumGate.new
    result = gate.evaluate(
      intent: "change",
      actions: [{ "type" => "run", "args" => { "cmd" => "go mod init example.com/app" } }],
      gaps: [
        { "id" => "g1", "field" => "module_name", "question" => "Go module?", "resolved" => false, "priority" => 1 }
      ]
    )

    assert_equal(1, result[:technical_blocking_gaps].size)
    assert_equal("module_name", result[:technical_blocking_gaps].first["field"])
  end

  def test_blocks_package_name_gap_for_node_fixture
    gate = Redwright::BootstrapMinimumGate.new
    result = gate.evaluate(
      intent: "change",
      actions: [{ "type" => "write_files", "args" => { "files" => { "package.json" => "{}" } } }],
      gaps: [
        { "id" => "g1", "field" => "package_name", "question" => "Package name?", "resolved" => false, "priority" => 1 }
      ]
    )

    assert_equal(1, result[:technical_blocking_gaps].size)
    assert_equal("package_name", result[:technical_blocking_gaps].first["field"])
  end

  def test_defers_optional_gaps_for_mutating_change
    gate = Redwright::BootstrapMinimumGate.new
    result = gate.evaluate(
      intent: "change",
      actions: [{ "type" => "write_file", "args" => {} }],
      gaps: [
        { "id" => "g1", "field" => "architecture_style", "question" => "Architecture style?", "resolved" => false, "priority" => 2 }
      ]
    )

    assert_equal(0, result[:technical_blocking_gaps].size)
    assert_equal(1, result[:alignment_optional_gaps].size)
  end

  def test_meta_intent_never_blocks
    gate = Redwright::BootstrapMinimumGate.new
    result = gate.evaluate(
      intent: "meta",
      actions: [{ "type" => "write_file", "args" => {} }],
      gaps: [
        { "id" => "g1", "field" => "project_name", "question" => "Project name?", "resolved" => false, "priority" => 1 }
      ]
    )

    assert_equal(0, result[:technical_blocking_gaps].size)
    assert_equal(1, result[:alignment_optional_gaps].size)
  end
end
