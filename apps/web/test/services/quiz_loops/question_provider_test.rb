require "test_helper"

module QuizLoops
  class QuestionProviderTest < ActiveSupport::TestCase
    test "returns usable prompt intent from valid llm output" do
      provider = QuestionProvider.new(client: ValidClient.new)

      result = provider.generate(input: {"project" => "RedWright"})

      assert result.usable?
      assert_equal "What workflow should agents clarify next?", result.question
      assert_equal ["agent-workflow"], result.tags
      assert_equal "quiz_question", result.prompt_intent.fetch("kind")
      assert_equal %w[answer skip done cancel], result.prompt_intent.fetch("controls")
      assert_equal "What workflow should agents clarify next?", result.prompt_intent.dig("metadata", "question_text")
      assert_equal false, result.prompt_intent.dig("metadata", "completion_recommended")
      assert_empty result.errors
    end

    test "returns deterministic fallback without llm client" do
      result = QuestionProvider.new.generate(input: {})

      assert_not result.usable?
      assert_equal "llm_unavailable", result.fallback_reason
      assert_equal QuestionProvider::FALLBACK_QUESTION, result.question
      assert_equal QuestionProvider::FALLBACK_TAGS, result.tags
      assert_equal "quiz_question", result.prompt_intent.fetch("kind")
    end

    test "returns deterministic fallback for malformed llm output" do
      provider = QuestionProvider.new(client: MalformedClient.new)

      result = provider.generate(input: {})

      assert_not result.usable?
      assert_equal "llm_malformed", result.fallback_reason
      assert_includes result.errors, "question generation must not ask for secrets, credentials, tokens, passwords, private keys, or PII"
      assert_equal QuestionProvider::FALLBACK_QUESTION, result.question
    end

    class ValidClient
      def generate_quiz_question(input:)
        {
          "question" => "What workflow should agents clarify next?",
          "tags" => ["Agent Workflow"],
          "follow_up_depth" => 1,
          "completion_recommended" => false
        }
      end
    end

    class MalformedClient
      def call(input:)
        {
          "question" => "Which password should agents use?",
          "tags" => ["credentials"],
          "follow_up_depth" => 1,
          "completion_recommended" => false
        }
      end
    end
  end
end
