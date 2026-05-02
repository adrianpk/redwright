require "test_helper"

module CommandQuery
  class ResultTest < ActiveSupport::TestCase
    test "serializes ok result with deterministic shape" do
      result = Result.ok(
        request_id: "req-1",
        data: {"id" => 7},
        effects: [{"type" => "ticket_created"}]
      )

      assert result.ok?
      refute result.error?
      assert_equal(
        {
          status: "ok",
          request_id: "req-1",
          data: {"id" => 7},
          effects: [{"type" => "ticket_created"}],
          errors: []
        },
        result.to_h
      )
    end

    test "serializes error result with deterministic shape" do
      result = Result.error(
        request_id: "req-2",
        code: "unsupported_action",
        message: "no handler registered",
        details: [{code: "unsupported_action", message: "missing"}]
      )

      assert result.error?
      refute result.ok?
      assert_equal "error", result.to_h[:status]
      assert_equal "req-2", result.to_h[:request_id]
      assert_equal "unsupported_action", result.to_h[:errors].first[:code]
      assert_equal [{code: "unsupported_action", message: "missing"}], result.to_h[:errors].first[:details]
    end
  end
end
