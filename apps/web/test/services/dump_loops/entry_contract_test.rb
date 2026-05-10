require "test_helper"

module DumpLoops
  class EntryContractTest < ActiveSupport::TestCase
    test "accepts structured entry polish output and normalizes tags" do
      result = EntryContract.new(max_tags: 3).validate(
        "polished_input" => "The checkout flow should stay simple.",
        "topic_heading" => "Checkout Flow",
        "derived_thread_hints" => ["Payment retries"],
        "tag_suggestions" => [" Checkout Flow ", "UX", "checkout-flow", "extra"],
        "warnings" => []
      )

      assert result.valid?
      assert_equal "The checkout flow should stay simple.", result.attributes.fetch("polished_input")
      assert_equal "Checkout Flow", result.attributes.fetch("topic_heading")
      assert_equal ["Payment retries"], result.attributes.fetch("derived_thread_hints")
      assert_equal ["checkout-flow", "ux", "extra"], result.attributes.fetch("tag_suggestions")
    end

    test "rejects hidden rationale and unexpected fields" do
      result = EntryContract.new.validate(
        "polished_input" => "Keep this.",
        "topic_heading" => nil,
        "derived_thread_hints" => [],
        "tag_suggestions" => [],
        "warnings" => [],
        "rationale" => "I changed this because..."
      )

      assert_not result.valid?
      assert_includes result.errors, "unexpected field: rationale"
    end

    test "rejects unredacted secret values" do
      result = EntryContract.new.validate(
        "polished_input" => "Use API_TOKEN=abc123 for the provider.",
        "topic_heading" => nil,
        "derived_thread_hints" => [],
        "tag_suggestions" => ["credentials"],
        "warnings" => []
      )

      assert_not result.valid?
      assert_includes result.errors, "dump polishing output must redact obvious secrets, credentials, tokens, passwords, and private keys"
    end

    test "requires polished input" do
      result = EntryContract.new.validate(
        "polished_input" => "",
        "topic_heading" => nil,
        "derived_thread_hints" => [],
        "tag_suggestions" => [],
        "warnings" => []
      )

      assert_not result.valid?
      assert_includes result.errors, "polished_input can't be blank"
    end
  end
end
