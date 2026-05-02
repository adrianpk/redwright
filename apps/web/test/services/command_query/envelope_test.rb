require "test_helper"

module CommandQuery
  class EnvelopeTest < ActiveSupport::TestCase
    test "builds valid command envelope from hash" do
      envelope = Envelope.from_hash(
        "kind" => "command",
        "name" => "CreateTicket",
        "payload" => {"title" => "Add API"},
        "execution_context" => {"actor_id" => "agent-coder"},
        "request_id" => "req-1"
      )

      assert envelope.valid?, envelope.errors.inspect
      assert envelope.command?
      refute envelope.query?
      assert_equal "CreateTicket", envelope.name
      assert_equal({"title" => "Add API"}, envelope.payload)
      assert_equal "req-1", envelope.request_id
    end

    test "rejects invalid envelope shape" do
      envelope = Envelope.from_hash(
        "kind" => "mutation",
        "name" => "",
        "payload" => [],
        "execution_context" => nil,
        "request_id" => ""
      )

      refute envelope.valid?
      assert_equal(
        ["invalid_envelope", "invalid_envelope", "invalid_payload", "invalid_envelope", "invalid_envelope"],
        envelope.errors.map { |error| error[:code] }
      )
    end
  end
end
