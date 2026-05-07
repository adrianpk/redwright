require "test_helper"

module QuizLoops
  class QuestionContractTest < ActiveSupport::TestCase
    test "accepts structured question output and normalizes tags" do
      result = QuestionContract.new.validate(
        "question" => "What should the checkout flow optimize first?",
        "tags" => [" Checkout Flow ", "UX", "checkout-flow"],
        "follow_up_depth" => 2,
        "completion_recommended" => false
      )

      assert result.valid?
      assert_equal "What should the checkout flow optimize first?", result.attributes.fetch("question")
      assert_equal ["checkout-flow", "ux"], result.attributes.fetch("tags")
      assert_equal 2, result.attributes.fetch("follow_up_depth")
      assert_equal false, result.attributes.fetch("completion_recommended")
    end

    test "bounds tags by configured maximum" do
      result = QuestionContract.new(max_tags: 3).validate(
        "question" => "What should be clarified?",
        "tags" => %w[one two three four],
        "follow_up_depth" => 1,
        "completion_recommended" => false
      )

      assert result.valid?
      assert_equal %w[one two three], result.attributes.fetch("tags")
    end

    test "accepts root follow up depth" do
      result = QuestionContract.new(max_follow_up_depth: 3).validate(
        "question" => "What should start this use case quiz?",
        "tags" => ["context"],
        "follow_up_depth" => 0,
        "completion_recommended" => false
      )

      assert result.valid?
      assert_equal 0, result.attributes.fetch("follow_up_depth")
    end

    test "rejects hidden rationale and unexpected fields" do
      result = QuestionContract.new.validate(
        "question" => "What should be clarified?",
        "tags" => ["context"],
        "follow_up_depth" => 1,
        "completion_recommended" => false,
        "rationale" => "I need to know this because..."
      )

      assert_not result.valid?
      assert_includes result.errors, "unexpected field: rationale"
    end

    test "rejects follow up depth beyond maximum" do
      result = QuestionContract.new(max_follow_up_depth: 3).validate(
        "question" => "What should be clarified?",
        "tags" => ["context"],
        "follow_up_depth" => 4,
        "completion_recommended" => false
      )

      assert_not result.valid?
      assert_includes result.errors, "follow_up_depth must be between 0 and 3"
    end

    test "rejects questions that ask for sensitive information" do
      result = QuestionContract.new.validate(
        "question" => "What API token should agents use?",
        "tags" => ["credentials"],
        "follow_up_depth" => 1,
        "completion_recommended" => false
      )

      assert_not result.valid?
      assert_includes result.errors, "question generation must not ask for secrets, credentials, tokens, passwords, private keys, or PII"
    end
  end
end
