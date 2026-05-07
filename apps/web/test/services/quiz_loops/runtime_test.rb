require "test_helper"

module QuizLoops
  class RuntimeTest < ActiveSupport::TestCase
    test "opens project quiz and returns next question" do
      project = create_project(key: "quiz-runtime-project")

      result = Runtime.new(project: project, question_provider: StaticQuestionProvider.new).open

      assert result.ok?
      assert_equal "collecting", result.status
      assert_equal project.main_quiz, result.quiz
      assert_equal "What should be clarified next?", result.question
      assert_equal ["project-context"], result.tags
      assert_equal "What should be clarified next?", result.quiz.current_question
      assert_equal ["project-context"], result.quiz.current_tags
      assert_equal "quiz_question", result.quiz.current_prompt_intent.fetch("kind")
    end

    test "reopens existing current question without regenerating it" do
      project = create_project(key: "quiz-runtime-current-state")
      provider = CountingQuestionProvider.new
      runtime = Runtime.new(project: project, question_provider: provider)

      first = runtime.open
      second = runtime.open

      assert_equal 1, provider.calls
      assert_equal first.question, second.question
      assert_equal first.tags, second.tags
      assert_equal first.prompt_intent, second.prompt_intent
    end

    test "stores explicit routing state on generated current question" do
      project = create_project(key: "quiz-runtime-routing-state")
      runtime = Runtime.new(project: project, question_provider: StaticQuestionProvider.new)

      result = runtime.open
      routing_state = result.prompt_intent.dig("metadata", "routing_state")

      assert_equal "trunk", routing_state.fetch("phase")
      assert_equal 0, routing_state.fetch("entry_count")
      assert_equal 50, routing_state.fetch("remaining_questions")
      assert_equal 1, routing_state.fetch("follow_up_depth")
      assert_equal 3, routing_state.fetch("max_follow_up_depth")
      assert_equal false, routing_state.fetch("trunk_return_recommended")
      assert_equal [], routing_state.fetch("covered_tags")
    end

    test "returns to trunk when follow up depth is exhausted" do
      project = create_project(key: "quiz-runtime-trunk-return")
      quiz = project.find_or_create_main_quiz!
      quiz.store_current_question!(
        question: "What detail should we inspect?",
        tags: ["local-detail"],
        prompt_intent: PromptIntentBuilder.question(
          question: "What detail should we inspect?",
          tags: ["local-detail"],
          follow_up_depth: 3,
          completion_recommended: false
        ),
        fallback_reason: "",
        errors: []
      )
      runtime = Runtime.new(
        project: project,
        question_provider: DeepFollowUpProvider.new,
        configuration: Configuration.new("max_follow_up_depth" => 3)
      )

      result = runtime.advance!(answer: "Keep asking locally.")

      assert_not result.prompt_intent.dig("metadata", "routing_state").fetch("trunk_return_recommended")
      assert_equal "follow_up_depth_exhausted", result.fallback_reason
      assert_equal Runtime::TRUNK_RETURN_QUESTION, result.question
      assert_equal 1, result.prompt_intent.dig("metadata", "follow_up_depth")
      assert_equal "trunk", result.prompt_intent.dig("metadata", "routing_state").fetch("phase")
    end

    test "opens use case quiz and creates use case when missing" do
      project = create_project(key: "quiz-runtime-use-case")

      result = Runtime.new(project: project, use_case_name: "Billing Flow", question_provider: StaticQuestionProvider.new).open

      use_case = project.use_cases.find_by!(slug: "billing-flow")
      assert_equal use_case.quiz, result.quiz
      assert_equal project.id, result.quiz.project_id
    end

    test "persists answered entry for current question and returns another question" do
      project = create_project(key: "quiz-runtime-answer")
      runtime = Runtime.new(project: project, question_provider: StaticQuestionProvider.new)
      quiz = project.find_or_create_main_quiz!
      quiz.store_current_question!(
        question: "What should agents know?",
        tags: ["Agent Context"],
        prompt_intent: { "kind" => "quiz_question" },
        fallback_reason: "",
        errors: []
      )

      result = runtime.advance!(
        question: "Ignored submitted question?",
        answer: "They should preserve ticket context.",
        tags: ["Ignored Tag"]
      )

      entry = project.quiz_entries.last
      assert_equal "collecting", result.status
      assert_equal entry, result.entry
      assert_equal "answered", entry.status
      assert_equal "What should agents know?", entry.question
      assert_equal "They should preserve ticket context.", entry.answer
      assert_equal ["agent-context"], entry.tags.map(&:name)
      assert_equal "What should be clarified next?", result.question
    end

    test "persists skipped entry for current question without answer" do
      project = create_project(key: "quiz-runtime-skip")
      runtime = Runtime.new(project: project, question_provider: StaticQuestionProvider.new)
      quiz = project.find_or_create_main_quiz!
      quiz.store_current_question!(
        question: "Can this be skipped?",
        tags: ["optional"],
        prompt_intent: { "kind" => "quiz_question" },
        fallback_reason: "",
        errors: []
      )

      result = runtime.advance!(question: "Ignored skip question?", answer: "skip")

      entry = project.quiz_entries.last
      assert_equal "collecting", result.status
      assert_equal "skipped", entry.status
      assert_equal "Can this be skipped?", entry.question
      assert_equal "", entry.answer
      assert_equal ["optional"], entry.tags.map(&:name)
    end

    test "done does not persist an entry and quiz can reopen" do
      project = create_project(key: "quiz-runtime-done")
      runtime = Runtime.new(project: project, question_provider: StaticQuestionProvider.new)
      quiz = project.find_or_create_main_quiz!
      quiz.store_current_question!(
        question: "Done?",
        tags: ["completion"],
        prompt_intent: { "kind" => "quiz_question" },
        fallback_reason: "",
        errors: []
      )

      result = runtime.advance!(question: "Ignored done question?", answer: "done")
      assert_nil quiz.reload.current_question

      reopened = runtime.open

      assert_equal "done", result.status
      assert_nil result.entry
      assert_equal 0, project.quiz_entries.count
      assert_equal "collecting", reopened.status
      assert_equal project.main_quiz, reopened.quiz
    end

    test "cancel does not persist an entry and quiz can reopen" do
      project = create_project(key: "quiz-runtime-cancel")
      runtime = Runtime.new(project: project, question_provider: StaticQuestionProvider.new)
      quiz = project.find_or_create_main_quiz!
      quiz.store_current_question!(
        question: "Cancel?",
        tags: ["cancellation"],
        prompt_intent: { "kind" => "quiz_question" },
        fallback_reason: "",
        errors: []
      )

      result = runtime.advance!(question: "Ignored cancel question?", answer: "cancel")
      assert_nil quiz.reload.current_question

      reopened = runtime.open

      assert_equal "cancelled", result.status
      assert_nil result.entry
      assert_equal 0, project.quiz_entries.count
      assert_equal "collecting", reopened.status
    end

    test "returns done when configured question limit is reached" do
      project = create_project(key: "quiz-runtime-limit")
      quiz = project.find_or_create_main_quiz!
      quiz.entries.create!(question: "Already asked?", answer: "Yes.")
      runtime = Runtime.new(
        project: project,
        question_provider: StaticQuestionProvider.new,
        configuration: Configuration.new("max_questions" => 1)
      )

      result = runtime.open

      assert_equal "done", result.status
      assert_nil result.question
    end

    class StaticQuestionProvider
      def generate(input:)
        QuestionProvider::Result.new(
          usable: true,
          question: "What should be clarified next?",
          tags: ["project-context"],
          follow_up_depth: 1,
          completion_recommended: false,
          prompt_intent: PromptIntentBuilder.question(
            question: "What should be clarified next?",
            tags: ["project-context"],
            follow_up_depth: 1,
            completion_recommended: false
          ),
          fallback_reason: "",
          errors: []
        )
      end
    end

    class CountingQuestionProvider < StaticQuestionProvider
      attr_reader :calls

      def initialize
        @calls = 0
      end

      def generate(input:)
        @calls += 1
        super
      end
    end

    class DeepFollowUpProvider
      def generate(input:)
        QuestionProvider::Result.new(
          usable: true,
          question: "Which local detail should we keep drilling into?",
          tags: ["local-detail"],
          follow_up_depth: 3,
          completion_recommended: false,
          prompt_intent: PromptIntentBuilder.question(
            question: "Which local detail should we keep drilling into?",
            tags: ["local-detail"],
            follow_up_depth: 3,
            completion_recommended: false
          ),
          fallback_reason: "",
          errors: []
        )
      end
    end
  end
end
