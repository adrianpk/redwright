require "test_helper"

module HeavyInteractionSagas
  class ContractTest < ActiveSupport::TestCase
    test "serializes the common saga contract with string keys" do
      contract = Contract.new(
        state: "collecting_context",
        stage: "questionnaire",
        status: "open",
        turns: [{question: "Project name?", answer: "rw"}],
        effects: [Effect.new(type: "turn_recorded", visibility: "internal")],
        next_prompt_intent: PromptIntent.new(kind: "question", slot: "repository"),
        terminal_reason: nil,
        metadata: {source_channel: "telegram"}
      )

      assert_equal Contract::FIELDS, contract.to_h.keys
      assert_equal(
        {
          "state" => "collecting_context",
          "stage" => "questionnaire",
          "status" => "open",
          "turns" => [{"question" => "Project name?", "answer" => "rw"}],
          "effects" => [{"type" => "turn_recorded", "visibility" => "internal"}],
          "next_prompt_intent" => {
            "kind" => "question",
            "slot" => "repository",
            "question_key" => nil,
            "controls" => [],
            "requiredness" => nil,
            "expected_input_shape" => nil,
            "locale" => nil,
            "llm_allowed" => nil,
            "metadata" => {}
          },
          "terminal_reason" => nil,
          "metadata" => {"source_channel" => "telegram"}
        },
        contract.to_h
      )
    end

    test "requires state stage and status" do
      error = assert_raises(ArgumentError) do
        Contract.new(state: "", stage: "questionnaire", status: "open")
      end

      assert_equal "state is required", error.message
    end
  end
end
