# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/runtime_state_contract"

class RuntimeStateContractTest < Minitest::Test
  def test_allows_known_transition
    assert(Redwright::RuntimeStateContract.allowed_transition?(from: "ready", to: "executing"))
  end

  def test_rejects_unknown_transition
    refute(Redwright::RuntimeStateContract.allowed_transition?(from: "blocked", to: "executing"))
    err = assert_raises(ArgumentError) do
      Redwright::RuntimeStateContract.assert_transition!(from: "blocked", to: "executing")
    end
    assert_match("invalid_runtime_transition", err.message)
  end

  def test_terminal_reason_contract
    assert(Redwright::RuntimeStateContract.valid_terminal_reason?("success"))
    refute(Redwright::RuntimeStateContract.valid_terminal_reason?("whatever"))
  end
end
