# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/alignment_sufficiency_heuristic"

class AlignmentSufficiencyHeuristicTest < Minitest::Test
  def test_requires_at_least_one_answered_turn
    heuristic = Redwright::AlignmentSufficiencyHeuristic.new
    refute(heuristic.sufficient?(objective: "minimal hello cli", answered_turns_count: 0))
  end

  def test_marks_trivial_scope_as_sufficient_after_one_turn
    heuristic = Redwright::AlignmentSufficiencyHeuristic.new
    assert(heuristic.sufficient?(objective: "minimal hello cli", answered_turns_count: 1))
  end
end
