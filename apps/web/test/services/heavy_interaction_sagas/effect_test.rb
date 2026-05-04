require "test_helper"

module HeavyInteractionSagas
  class EffectTest < ActiveSupport::TestCase
    test "serializes with deterministic visibility and payload" do
      effect = Effect.new(type: "project_created", visibility: "internal", data: {project_id: 7})

      assert_equal(
        {
          "type" => "project_created",
          "visibility" => "internal",
          "project_id" => 7
        },
        effect.to_h
      )
    end

    test "rejects unsupported visibility" do
      error = assert_raises(ArgumentError) do
        Effect.new(type: "project_created", visibility: "secret")
      end

      assert_equal "unsupported effect visibility: secret", error.message
    end
  end
end
