# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/project_new_context_contract"

class ProjectNewContextContractTest < Minitest::Test
  def test_slot_catalog_and_classification
    slots = Redwright::ProjectNewContextContract.slot_names
    assert_equal(true, slots.include?("project_name"))
    assert_equal(:blocking, Redwright::ProjectNewContextContract.slot_classification("project_name"))
    assert_equal(:high_impact_confirmation, Redwright::ProjectNewContextContract.slot_classification("framework"))
    assert_equal(:optional, Redwright::ProjectNewContextContract.slot_classification("constraints"))
  end

  def test_merge_context_prefers_user_then_inferred_then_defaults
    merged = Redwright::ProjectNewContextContract.merge_context(
      user_inputs: { "project_name" => "taskmaster", "description" => "cli", "framework" => "" },
      inferred_inputs: { "stack" => "go", "framework" => "cobra", "architecture_style" => "layered" },
      defaults_authorized_inputs: { "framework" => "stdlib", "test_strategy" => "table-driven" }
    )

    assert_equal("taskmaster", merged["project_name"])
    assert_equal("cli", merged["description"])
    assert_equal("go", merged["stack"])
    assert_equal("cobra", merged["framework"])
    assert_equal("layered", merged["architecture_style"])
    assert_equal("table-driven", merged["test_strategy"])
  end

  def test_sufficiency_for_rich_prompt_context
    ctx = {
      "project_name" => "taskmaster",
      "description" => "task cli",
      "stack" => "go",
      "framework" => "cobra"
    }

    status = Redwright::ProjectNewContextContract.sufficiency(
      context: ctx,
      proceed_with_defaults_confirmed: false
    )

    assert_equal(true, status[:ready_to_execute])
    assert_equal([], status[:unresolved_blocking_slots])
  end

  def test_sufficiency_for_sparse_context_requires_blocking_answers
    ctx = {
      "project_name" => "taskmaster",
      "description" => "",
      "stack" => nil
    }

    status = Redwright::ProjectNewContextContract.sufficiency(
      context: ctx,
      proceed_with_defaults_confirmed: false
    )

    assert_equal(false, status[:ready_to_execute])
    assert_equal(%w[description stack], status[:unresolved_blocking_slots])
  end

  def test_sufficiency_allows_proceed_with_defaults_when_confirmed
    ctx = {
      "project_name" => "taskmaster",
      "description" => "",
      "stack" => nil
    }

    status = Redwright::ProjectNewContextContract.sufficiency(
      context: ctx,
      proceed_with_defaults_confirmed: true
    )

    assert_equal(true, status[:ready_to_execute])
    assert_equal(%w[description stack], status[:unresolved_blocking_slots])
  end

  def test_no_reask_for_resolved_slot
    resolved = { "stack" => "go", "project_name" => "taskmaster" }
    refute(
      Redwright::ProjectNewContextContract.should_reask_slot?(slot: "stack", resolved_fields: resolved)
    )
    assert(
      Redwright::ProjectNewContextContract.should_reask_slot?(slot: "framework", resolved_fields: resolved)
    )
  end

  def test_unresolved_slots_filtered_by_classification
    ctx = {
      "project_name" => "taskmaster",
      "description" => "cli",
      "stack" => "go",
      "framework" => "",
      "architecture_style" => nil,
      "constraints" => ""
    }

    high_impact = Redwright::ProjectNewContextContract.unresolved_slots(
      ctx,
      classifications: [:high_impact_confirmation]
    )
    optional = Redwright::ProjectNewContextContract.unresolved_slots(
      ctx,
      classifications: [:optional]
    )

    assert_equal(%w[framework architecture_style], high_impact)
    assert_equal(%w[test_strategy packaging_module_convention constraints], optional)
  end

  def test_assert_known_slot_raises_on_unknown_slot
    err = assert_raises(ArgumentError) do
      Redwright::ProjectNewContextContract.assert_known_slot!("unexpected_slot")
    end
    assert_match("unknown_project_new_slot", err.message)
  end
end
