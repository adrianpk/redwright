module QuizLoops
  class QuestionProvider
    FALLBACK_QUESTION = "What should this project preserve or clarify next?".freeze
    FALLBACK_TAGS = %w[project-context].freeze

    Result = Struct.new(
      :usable,
      :question,
      :tags,
      :follow_up_depth,
      :completion_recommended,
      :prompt_intent,
      :fallback_reason,
      :errors,
      keyword_init: true
    ) do
      def usable?
        usable == true
      end
    end

    def initialize(client: nil, contract: QuestionContract.new)
      @client = client
      @contract = contract
    end

    def generate(input:)
      return fallback_result(reason: "llm_unavailable", errors: ["LLM question client is not configured"]) unless client

      validation = contract.validate(raw_output_for(input))
      return usable_result(validation.attributes) if validation.valid?

      fallback_result(reason: "llm_malformed", errors: validation.errors)
    rescue StandardError => e
      fallback_result(reason: "llm_unavailable", errors: [e.message])
    end

    private

    attr_reader :client, :contract

    def raw_output_for(input)
      return client.generate_quiz_question(input: input) if client.respond_to?(:generate_quiz_question)
      return client.call(input: input) if client.respond_to?(:call)

      raise ArgumentError, "LLM question client does not implement generate_quiz_question or call"
    end

    def usable_result(attributes)
      Result.new(
        usable: true,
        question: attributes.fetch("question"),
        tags: attributes.fetch("tags"),
        follow_up_depth: attributes.fetch("follow_up_depth"),
        completion_recommended: attributes.fetch("completion_recommended"),
        prompt_intent: prompt_intent_for(attributes),
        fallback_reason: "",
        errors: []
      )
    end

    def fallback_result(reason:, errors:)
      attributes = {
        "question" => FALLBACK_QUESTION,
        "tags" => FALLBACK_TAGS,
        "follow_up_depth" => 1,
        "completion_recommended" => false
      }
      Result.new(
        usable: false,
        question: attributes.fetch("question"),
        tags: attributes.fetch("tags"),
        follow_up_depth: attributes.fetch("follow_up_depth"),
        completion_recommended: attributes.fetch("completion_recommended"),
        prompt_intent: prompt_intent_for(attributes),
        fallback_reason: reason,
        errors: errors
      )
    end

    def prompt_intent_for(attributes)
      PromptIntentBuilder.question(
        question: attributes.fetch("question"),
        tags: attributes.fetch("tags"),
        follow_up_depth: attributes.fetch("follow_up_depth"),
        completion_recommended: attributes.fetch("completion_recommended")
      )
    end
  end
end
