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
    end

    test "opens use case quiz and creates use case when missing" do
      project = create_project(key: "quiz-runtime-use-case")

      result = Runtime.new(project: project, use_case_name: "Billing Flow", question_provider: StaticQuestionProvider.new).open

      use_case = project.use_cases.find_by!(slug: "billing-flow")
      assert_equal use_case.quiz, result.quiz
      assert_equal project.id, result.quiz.project_id
    end

    test "persists answered entry and returns another question" do
      project = create_project(key: "quiz-runtime-answer")
      runtime = Runtime.new(project: project, question_provider: StaticQuestionProvider.new)

      result = runtime.advance!(
        question: "What should agents know?",
        answer: "They should preserve ticket context.",
        tags: ["Agent Context"]
      )

      entry = project.quiz_entries.last
      assert_equal "collecting", result.status
      assert_equal entry, result.entry
      assert_equal "answered", entry.status
      assert_equal "They should preserve ticket context.", entry.answer
      assert_equal ["agent-context"], entry.tags.map(&:name)
      assert_equal "What should be clarified next?", result.question
    end

    test "persists skipped entry without answer" do
      project = create_project(key: "quiz-runtime-skip")
      runtime = Runtime.new(project: project, question_provider: StaticQuestionProvider.new)

      result = runtime.advance!(question: "Can this be skipped?", answer: "skip", tags: ["optional"])

      entry = project.quiz_entries.last
      assert_equal "collecting", result.status
      assert_equal "skipped", entry.status
      assert_equal "", entry.answer
      assert_equal ["optional"], entry.tags.map(&:name)
    end

    test "done does not persist an entry and quiz can reopen" do
      project = create_project(key: "quiz-runtime-done")
      runtime = Runtime.new(project: project, question_provider: StaticQuestionProvider.new)

      result = runtime.advance!(question: "Done?", answer: "done")
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

      result = runtime.advance!(question: "Cancel?", answer: "cancel")
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
  end
end
