require "test_helper"

module DumpLoops
  class CuratedDumpContractTest < ActiveSupport::TestCase
    test "accepts curated dump output and normalizes tags" do
      result = CuratedDumpContract.new(max_tags: 2).validate(
        "central_topic" => "Conversation Capture",
        "summary" => "Dump captures user-led context.",
        "key_concepts" => ["Dump", "Quiz"],
        "decisions_or_preferences" => ["Use Conversation as the entrypoint."],
        "tensions_and_tradeoffs" => ["Textarea versus repeated posts."],
        "assumptions" => ["Single-user product."],
        "derived_threads" => ["Export to ops artifacts."],
        "possible_downstream_artifacts" => ["Spec", "Plan"],
        "open_questions" => ["Should export ship now?"],
        "tag_suggestions" => [" Conversation ", "Dump", "conversation"]
      )

      assert result.valid?
      assert_equal "Conversation Capture", result.attributes.fetch("central_topic")
      assert_equal ["Dump", "Quiz"], result.attributes.fetch("key_concepts")
      assert_equal ["conversation", "dump"], result.attributes.fetch("tag_suggestions")
    end

    test "rejects hidden rationale and unexpected fields" do
      result = CuratedDumpContract.new.validate(valid_payload.merge("rationale" => "Internal reasoning"))

      assert_not result.valid?
      assert_includes result.errors, "unexpected field: rationale"
    end

    test "requires central topic and summary" do
      result = CuratedDumpContract.new.validate(valid_payload.merge("central_topic" => "", "summary" => ""))

      assert_not result.valid?
      assert_includes result.errors, "central_topic can't be blank"
      assert_includes result.errors, "summary can't be blank"
    end

    private

    def valid_payload
      {
        "central_topic" => "Dump",
        "summary" => "Summary",
        "key_concepts" => [],
        "decisions_or_preferences" => [],
        "tensions_and_tradeoffs" => [],
        "assumptions" => [],
        "derived_threads" => [],
        "possible_downstream_artifacts" => [],
        "open_questions" => [],
        "tag_suggestions" => []
      }
    end
  end
end
