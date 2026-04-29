# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/runtime_session_transfer"

class RuntimeSessionTransferTest < Minitest::Test
  def test_transfer_rewrites_runtime_and_preserves_previous_runtime
    transfer = Redwright::RuntimeSessionTransfer.new
    source = { "session_id" => "s-1", "runtime" => "interactive", "payload" => { "x" => 1 } }

    result = transfer.transfer(session: source, from_runtime: "interactive", to_runtime: "factory")

    assert_equal("factory", result.session["runtime"])
    assert_equal("interactive", result.session["previous_runtime"])
    assert(result.transferred_at.to_s.size > 10)
  end

  def test_transfer_rejects_unknown_runtime
    transfer = Redwright::RuntimeSessionTransfer.new

    err = assert_raises(ArgumentError) do
      transfer.transfer(session: {}, from_runtime: "interactive", to_runtime: "other")
    end

    assert_equal("unsupported runtime: other", err.message)
  end

  def test_transfer_rejects_non_hash_session
    transfer = Redwright::RuntimeSessionTransfer.new

    err = assert_raises(ArgumentError) do
      transfer.transfer(session: [], from_runtime: "interactive", to_runtime: "factory")
    end

    assert_equal("session must be hash", err.message)
  end
end
