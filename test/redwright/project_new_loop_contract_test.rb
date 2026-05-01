# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/project_new_loop_contract"

class ProjectNewLoopContractTest < Minitest::Test
  def test_state_and_terminal_contract
    assert(Redwright::ProjectNewLoopContract.valid_state?("collecting_context"))
    refute(Redwright::ProjectNewLoopContract.valid_state?("unknown"))

    assert(Redwright::ProjectNewLoopContract.valid_terminal_outcome?("confirmed_and_executed"))
    refute(Redwright::ProjectNewLoopContract.valid_terminal_outcome?("whatever"))
  end

  def test_transition_matrix
    expected = {
      "collecting_context" => %w[
        collecting_context
        awaiting_blocking_answers
        awaiting_high_impact_confirmation
        ready_to_execute
        cancelled
      ],
      "awaiting_blocking_answers" => %w[
        awaiting_blocking_answers
        awaiting_high_impact_confirmation
        ready_to_execute
        cancelled
      ],
      "awaiting_high_impact_confirmation" => %w[
        awaiting_high_impact_confirmation
        ready_to_execute
        cancelled
      ],
      "ready_to_execute" => %w[
        executing
        cancelled
      ],
      "executing" => %w[
        done
        cancelled
      ],
      "done" => [],
      "cancelled" => []
    }

    all_states = expected.keys
    all_states.each do |from|
      all_states.each do |to|
        should_allow = expected.fetch(from).include?(to)
        assert_equal(
          should_allow,
          Redwright::ProjectNewLoopContract.allowed_transition?(from: from, to: to),
          "transition mismatch from=#{from} to=#{to}"
        )
      end
    end
  end

  def test_assert_transition_raises_for_invalid_transition
    err = assert_raises(ArgumentError) do
      Redwright::ProjectNewLoopContract.assert_transition!(from: "ready_to_execute", to: "done")
    end
    assert_match("invalid_project_new_loop_transition", err.message)
  end

  def test_execution_guard
    assert(
      Redwright::ProjectNewLoopContract.execution_allowed?(
        blocking_resolved: true,
        proceed_with_defaults_confirmed: false
      )
    )
    assert(
      Redwright::ProjectNewLoopContract.execution_allowed?(
        blocking_resolved: false,
        proceed_with_defaults_confirmed: true
      )
    )
    refute(
      Redwright::ProjectNewLoopContract.execution_allowed?(
        blocking_resolved: false,
        proceed_with_defaults_confirmed: false
      )
    )
  end

  def test_assert_execution_guard_raises_when_not_allowed
    err = assert_raises(ArgumentError) do
      Redwright::ProjectNewLoopContract.assert_execution_allowed!(
        blocking_resolved: false,
        proceed_with_defaults_confirmed: false
      )
    end
    assert_match("project_new_execution_not_allowed", err.message)
  end
end
