# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/alignment_contract"

class AlignmentContractTest < Minitest::Test
  def test_terminal_status_whitelist
    assert_equal(true, Redwright::AlignmentContract.valid_terminal_status?("continue"))
    assert_equal(true, Redwright::AlignmentContract.valid_terminal_status?("ready"))
    assert_equal(true, Redwright::AlignmentContract.valid_terminal_status?("user_stop"))
    assert_equal(true, Redwright::AlignmentContract.valid_terminal_status?("blocked"))
    assert_equal(false, Redwright::AlignmentContract.valid_terminal_status?("done"))
  end

  def test_transition_rules
    assert_equal(true, Redwright::AlignmentContract.allowed_transition?(from: "collecting_context", to: "waiting_user"))
    assert_equal(true, Redwright::AlignmentContract.allowed_transition?(from: "waiting_user", to: "ready"))
    assert_equal(true, Redwright::AlignmentContract.allowed_transition?(from: "waiting_user", to: "paused"))
    assert_equal(false, Redwright::AlignmentContract.allowed_transition?(from: "ready", to: "collecting_context"))
  end
end
