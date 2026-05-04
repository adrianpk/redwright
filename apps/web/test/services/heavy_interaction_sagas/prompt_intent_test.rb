require "test_helper"

module HeavyInteractionSagas
  class PromptIntentTest < ActiveSupport::TestCase
    test "serializes structured prompt intent fields" do
      intent = PromptIntent.new(
        kind: "question",
        slot: "repository",
        question_key: "repository_url",
        controls: [{type: "text"}],
        requiredness: "blocking",
        expected_input_shape: "string",
        locale: "en",
        llm_allowed: false,
        metadata: {source: "project_setup"}
      )

      assert_equal(
        {
          "kind" => "question",
          "slot" => "repository",
          "question_key" => "repository_url",
          "controls" => [{"type" => "text"}],
          "requiredness" => "blocking",
          "expected_input_shape" => "string",
          "locale" => "en",
          "llm_allowed" => false,
          "metadata" => {"source" => "project_setup"}
        },
        intent.to_h
      )
    end

    test "requires a kind" do
      error = assert_raises(ArgumentError) do
        PromptIntent.new(kind: nil)
      end

      assert_equal "prompt intent kind is required", error.message
    end
  end
end
