module QuizLoops
  class PromptIntentBuilder
    CONTROLS = %w[answer skip done cancel].freeze

    class << self
      def question(question:, tags:, follow_up_depth:, completion_recommended:, routing_state: {})
        HeavyInteractionSagas::PromptIntent.new(
          kind: "quiz_question",
          controls: CONTROLS,
          expected_input_shape: "free_text_or_control",
          locale: "auto",
          llm_allowed: true,
          metadata: {
            "question_text" => question.to_s,
            "tags" => tags,
            "follow_up_depth" => follow_up_depth,
            "completion_recommended" => completion_recommended,
            "routing_state" => routing_state
          }
        ).to_h
      end
    end
  end
end
