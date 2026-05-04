require "test_helper"

module HeavyInteractionSagas
  class StepResultTest < ActiveSupport::TestCase
    test "serializes structured step result with effects and reconciliation" do
      result = StepResult.new(
        status: "needs_reconciliation",
        data: {project_id: 7},
        effects: [Effect.new(type: "project_created", visibility: "public")],
        errors: [{code: "workspace_failed"}],
        reconciliation: {retry_safe: false}
      )

      assert_equal(
        {
          "status" => "needs_reconciliation",
          "data" => {"project_id" => 7},
          "effects" => [{"type" => "project_created", "visibility" => "public"}],
          "errors" => [{"code" => "workspace_failed"}],
          "reconciliation" => {"retry_safe" => false}
        },
        result.to_h
      )
    end

    test "supports lightweight ok result" do
      result = StepResult.ok

      assert_equal "ok", result.to_h["status"]
      assert_equal({}, result.to_h["data"])
      assert_equal([], result.to_h["effects"])
      assert_equal([], result.to_h["errors"])
      assert_equal({}, result.to_h["reconciliation"])
    end

    test "rejects unsupported status" do
      error = assert_raises(ArgumentError) do
        StepResult.new(status: "unknown")
      end

      assert_equal "unsupported step result status: unknown", error.message
    end
  end
end
