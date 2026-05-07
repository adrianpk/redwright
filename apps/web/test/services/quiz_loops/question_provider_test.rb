require "test_helper"

module QuizLoops
  class QuestionProviderTest < ActiveSupport::TestCase
    test "returns usable prompt intent from valid llm output" do
      provider = QuestionProvider.new(request_engine: ValidRequestEngine.new, model: "test/model", provider: "test")

      result = provider.generate(input: {"project" => "RedWright"})

      assert result.usable?
      assert_equal "What workflow should agents clarify next?", result.question
      assert_equal ["agent-workflow"], result.tags
      assert_equal "quiz_question", result.prompt_intent.fetch("kind")
      assert_equal %w[answer skip done cancel], result.prompt_intent.fetch("controls")
      assert_equal "What workflow should agents clarify next?", result.prompt_intent.dig("metadata", "question_text")
      assert_equal false, result.prompt_intent.dig("metadata", "completion_recommended")
      assert_equal({}, result.prompt_intent.dig("metadata", "routing_state"))
      assert_empty result.errors
    end

    test "uses deep generation by default" do
      engine = CapturingRequestEngine.new([self.class.valid_response("What deep question should agents clarify next?")])
      provider = QuestionProvider.new(request_engine: engine, model: "test/model", provider: "test")

      result = provider.generate(input: {"quiz" => {"mode" => "deep"}})

      assert result.usable?
      assert_equal ["quiz_question_generation"], engine.actions
      assert_equal "What deep question should agents clarify next?", result.question
    end

    test "routes fast mode through fast request engine contract" do
      engine = CapturingRequestEngine.new([self.class.valid_response("What fast question should agents answer next?")])
      provider = QuestionProvider.new(request_engine: engine, model: "test/model", provider: "test")

      result = provider.generate(input: {"quiz" => {"mode" => "fast"}})

      assert result.usable?
      assert_equal ["quiz_fast_question_generation"], engine.actions
      assert_equal "What fast question should agents answer next?", result.question
    end

    test "falls back to deep generation when fast generation is unavailable" do
      engine = CapturingRequestEngine.new([
        self.class.unavailable_response("provider timeout"),
        self.class.valid_response("What deep fallback question should agents answer next?")
      ])
      provider = QuestionProvider.new(request_engine: engine, model: "test/model", provider: "test")

      result = provider.generate(input: {"quiz" => {"mode" => "fast"}})

      assert result.usable?
      assert_equal ["quiz_fast_question_generation", "quiz_question_generation"], engine.actions
      assert_equal "What deep fallback question should agents answer next?", result.question
      assert_equal "", result.fallback_reason
    end

    test "falls back to deep generation when fast generation is invalid" do
      engine = CapturingRequestEngine.new([
        self.class.malformed_response,
        self.class.valid_response("What validated deep question should agents answer next?")
      ])
      provider = QuestionProvider.new(request_engine: engine, model: "test/model", provider: "test")

      result = provider.generate(input: {"quiz" => {"mode" => "fast"}})

      assert result.usable?
      assert_equal ["quiz_fast_question_generation", "quiz_question_generation"], engine.actions
      assert_equal "What validated deep question should agents answer next?", result.question
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
      provider = QuestionProvider.new(request_engine: MalformedRequestEngine.new, model: "test/model", provider: "test")

      result = provider.generate(input: {})

      assert_not result.usable?
      assert_equal "llm_malformed", result.fallback_reason
      assert_includes result.errors, "question generation must not ask for secrets, credentials, tokens, passwords, private keys, or PII"
      assert_equal QuestionProvider::FALLBACK_QUESTION, result.question
    end

    class ValidRequestEngine
      def generate_structured_message(**)
        QuestionProviderTest.valid_response("What workflow should agents clarify next?")
      end
    end

    class MalformedRequestEngine
      def generate_structured_message(**)
        QuestionProviderTest.malformed_response
      end
    end

    class CapturingRequestEngine
      attr_reader :actions

      def initialize(responses)
        @responses = responses
        @actions = []
      end

      def generate_structured_message(action:, **)
        actions << action
        responses.shift
      end

      private

      attr_reader :responses
    end

    class << self
      def valid_response(question)
        Redwright::LLM::RequestEngine::Response.new(
          status: "ok",
          semantic_payload: {
            "question" => question,
            "tags" => ["Agent Workflow"],
            "follow_up_depth" => 1,
            "completion_recommended" => false
          },
          rendered_text: question,
          provider_metadata: {finish_reason: "stop"},
          warnings: [],
          raw_response_ref: "{}"
        )
      end

      def malformed_response
        Redwright::LLM::RequestEngine::Response.new(
          status: "ok",
          semantic_payload: {
            "question" => "Which password should agents use?",
            "tags" => ["credentials"],
            "follow_up_depth" => 1,
            "completion_recommended" => false
          },
          rendered_text: "Which password should agents use?",
          provider_metadata: {finish_reason: "stop"},
          warnings: [],
          raw_response_ref: "{}"
        )
      end

      def unavailable_response(message)
        Redwright::LLM::RequestEngine::Response.new(
          status: "error",
          semantic_payload: {},
          rendered_text: "",
          provider_metadata: {},
          warnings: [message],
          raw_response_ref: ""
        )
      end
    end
  end
end
