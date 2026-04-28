# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/planner_contract"

class PlannerContractTest < Minitest::Test
  def test_allowed_action_types_prompt_lines_cover_primitives_and_macros
    lines = Redwright::PlannerContract.allowed_action_types_prompt_lines

    Redwright::PlannerContract::ACTION_PRIMITIVE_TYPES.each do |type|
      assert_includes(lines, "- #{type}")
    end

    assert_includes(lines, "- write_files (macro, expands to write_file)")
    assert_includes(lines, "- run_command (macro, expands to run)")
    assert_includes(lines, "- run_commands (macro, expands to run sequence)")
  end

  def test_system_prompt_includes_all_allowed_action_type_lines
    prompt = Redwright::PlannerContract::SYSTEM_PROMPT
    Redwright::PlannerContract.allowed_action_types_prompt_lines.each do |line|
      assert_includes(prompt, line)
    end
  end
end
