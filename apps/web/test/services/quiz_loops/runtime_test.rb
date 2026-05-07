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
      assert_equal "deep", result.quiz.mode
    end

    test "passes current quiz mode to question provider input" do
      project = create_project(key: "quiz-runtime-mode-input")
      provider = CapturingQuestionProvider.new
      quiz = project.find_or_create_main_quiz!
      quiz.update!(mode: "fast")

      Runtime.new(project: project, question_provider: provider).open

      assert_equal "fast", provider.inputs.last.fetch("quiz").fetch("mode")
    end

    test "passes current question context to question provider input" do
      project = create_project(key: "quiz-runtime-current-question-input")
      provider = CapturingQuestionProvider.new
      quiz = project.find_or_create_main_quiz!
      quiz.store_current_question!(
        question: "What question should not repeat?",
        tags: ["repeat-guard"],
        prompt_intent: {"kind" => "quiz_question"},
        fallback_reason: "",
        errors: []
      )

      Runtime.new(project: project, question_provider: provider).advance!(answer: "Skip repetition.")

      current_question = provider.inputs.last.fetch("current_question")
      assert_equal "What question should not repeat?", current_question.fetch("question")
      assert_equal ["repeat-guard"], current_question.fetch("tags")
    end

    test "fast mode activates generated question through candidate lifecycle" do
      project = create_project(key: "quiz-runtime-fast-candidate")
      provider = FastQuestionProvider.new
      quiz = project.find_or_create_main_quiz!
      quiz.update!(mode: "fast")

      result = Runtime.new(project: project, question_provider: provider).open

      candidate = quiz.reload.candidate_questions.first
      assert_equal "collecting", result.status
      assert_equal "What fast candidate should be activated?", result.question
      assert_equal "What fast candidate should be activated?", quiz.current_question
      assert_equal "activated", candidate.fetch("status")
      assert_equal "batch-0-1", candidate.fetch("branch_key")
      assert_equal 3, quiz.candidate_questions.count
      assert_equal 0, quiz.entries.count
      assert_equal 0, Tag.where(name: "fast-candidate").count
    end

    test "fast mode advances through queued batch without another llm call" do
      project = create_project(key: "quiz-runtime-fast-batch-local")
      provider = FastQuestionProvider.new
      quiz = project.find_or_create_main_quiz!
      quiz.update!(mode: "fast")
      runtime = Runtime.new(project: project, question_provider: provider)

      first = runtime.open
      second = runtime.advance!(answer: "skip")
      third = runtime.advance!(answer: "skip")

      assert_equal 1, provider.calls
      assert_equal "What fast candidate should be activated?", first.question
      assert_equal "What second fast candidate should be activated?", second.question
      assert_equal "What third fast candidate should be activated?", third.question
      assert_equal ["activated", "activated", "activated"], quiz.reload.candidate_questions.map { |candidate| candidate.fetch("status") }
    end

    test "answered fast question uses queued batch before another llm call" do
      project = create_project(key: "quiz-runtime-fast-answer-fallback")
      provider = FastQuestionProvider.new
      quiz = project.find_or_create_main_quiz!
      quiz.update!(mode: "fast")
      runtime = Runtime.new(project: project, question_provider: provider)

      runtime.open
      result = runtime.advance!(answer: "This answer should not force immediate LLM.")

      assert_equal 1, provider.calls
      assert_equal "What second fast candidate should be activated?", result.question
    end

    test "skipped fast question keeps deterministic fast progression input" do
      project = create_project(key: "quiz-runtime-fast-skip-progression")
      provider = CapturingQuestionProvider.new
      quiz = project.find_or_create_main_quiz!
      quiz.update!(mode: "fast")
      quiz.store_current_question!(
        question: "Can this fast question be skipped?",
        tags: ["fast-candidate"],
        prompt_intent: {"kind" => "quiz_question"},
        fallback_reason: "",
        errors: []
      )

      Runtime.new(project: project, question_provider: provider).advance!(answer: "skip")

      assert_equal "fast", provider.inputs.last.fetch("quiz").fetch("mode")
    end

    test "repeated fast question falls back to deep generation" do
      project = create_project(key: "quiz-runtime-fast-repeat-fallback")
      provider = RepeatingFastThenDeepProvider.new
      quiz = project.find_or_create_main_quiz!
      quiz.update!(mode: "fast")
      quiz.store_current_question!(
        question: "What question should not repeat?",
        tags: ["repeat-guard"],
        prompt_intent: {"kind" => "quiz_question"},
        fallback_reason: "",
        errors: []
      )

      result = Runtime.new(project: project, question_provider: provider).advance!(answer: "skip")

      assert_equal ["fast", "deep"], provider.modes
      assert_equal "What deep replacement should be asked?", result.question
      assert_equal "What deep replacement should be asked?", quiz.reload.current_question
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
      assert_equal "deep", routing_state.fetch("mode")
      assert_equal QuestionProvider::DEEP_STRATEGY, routing_state.fetch("generation_strategy")
      assert_equal "", routing_state.fetch("fallback_reason")
      assert_equal 0, routing_state.fetch("candidate_count")
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

    test "cleans stale unused candidates before generating the next question" do
      project = create_project(key: "quiz-runtime-candidate-cleanup")
      quiz = project.find_or_create_main_quiz!
      stale = quiz.add_candidate!(question: "Stale?", tags: ["Stale"], prompt_intent: {})
      active = quiz.add_candidate!(question: "Active?", tags: ["Active"], prompt_intent: {})
      stale_record = stale.merge("created_at" => 2.days.ago.iso8601)
      quiz.update!(candidate_questions: [stale_record, active])

      Runtime.new(project: project, question_provider: StaticQuestionProvider.new).open

      retained_questions = quiz.reload.candidate_questions.map { |candidate| candidate.fetch("question") }
      assert_equal ["Active?"], retained_questions
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

    class FastQuestionProvider
      attr_reader :calls

      def initialize
        @calls = 0
      end

      def generate(input:)
        @calls += 1
        candidates = [
          ["What fast candidate should be activated?", ["fast-candidate"]],
          ["What second fast candidate should be activated?", ["fast-candidate"]],
          ["What third fast candidate should be activated?", ["fast-candidate"]]
        ].map do |question, tags|
          {
            "question" => question,
            "tags" => tags,
            "follow_up_depth" => 1,
            "completion_recommended" => false
          }
        end

        QuestionProvider::Result.new(
          usable: true,
          question: candidates.first.fetch("question"),
          tags: candidates.first.fetch("tags"),
          follow_up_depth: 1,
          completion_recommended: false,
          prompt_intent: PromptIntentBuilder.question(
            question: candidates.first.fetch("question"),
            tags: candidates.first.fetch("tags"),
            follow_up_depth: 1,
            completion_recommended: false
          ),
          fallback_reason: "",
          errors: [],
          generation_strategy: QuestionProvider::FAST_STRATEGY,
          candidates: candidates
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

    class CapturingQuestionProvider < StaticQuestionProvider
      attr_reader :inputs

      def initialize
        @inputs = []
      end

      def generate(input:)
        inputs << input
        super
      end
    end

    class RepeatingFastThenDeepProvider
      attr_reader :modes

      def initialize
        @modes = []
      end

      def generate(input:)
        mode = input.fetch("quiz").fetch("mode")
        modes << mode
        question = mode == "fast" ? "What question should not repeat?" : "What deep replacement should be asked?"

        QuestionProvider::Result.new(
          usable: true,
          question: question,
          tags: ["repeat-guard"],
          follow_up_depth: 1,
          completion_recommended: false,
          prompt_intent: PromptIntentBuilder.question(
            question: question,
            tags: ["repeat-guard"],
            follow_up_depth: 1,
            completion_recommended: false
          ),
          fallback_reason: "",
          errors: [],
          generation_strategy: mode == "fast" ? QuestionProvider::FAST_STRATEGY : QuestionProvider::DEEP_STRATEGY
        )
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
