require "test_helper"

module QuizContext
  class RetrievalQueryTest < ActiveSupport::TestCase
    test "retrieves quiz entries and tickets by shared project use case and tag" do
      project = create_project(key: "quiz-context-retrieval")
      board = create_board(project_key: "quiz-context-retrieval-board", project: project)
      column = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      use_case = create_use_case(project: project, name: "Billing")
      quiz = use_case.find_or_create_quiz!
      entry = quiz.entries.create!(question: "What matters?", answer: "Monthly invoices.")
      ticket = board.tickets.create!(column: column, title: "Implement billing", use_case: use_case)
      other_entry = project.find_or_create_main_quiz!.entries.create!(question: "Global?", answer: "Global answer.")

      entry.tag_with!("billing")
      ticket.tag_with!("billing")
      other_entry.tag_with!("billing")

      result = RetrievalQuery.new(project: project, use_case: use_case, tags: ["Billing"]).call

      assert_equal [entry], result.quiz_entries.to_a
      assert_equal [ticket], result.tickets.to_a
      assert_equal 2, result.taggings.size
    end

    test "retrieves project scoped quiz entries when no use case is provided" do
      project = create_project(key: "quiz-context-project")
      quiz = project.find_or_create_main_quiz!
      entry = quiz.entries.create!(question: "What is global?", answer: "Project-wide context.")
      entry.tag_with!("project")

      result = RetrievalQuery.new(project: project, tags: ["project"]).call

      assert_equal [entry], result.quiz_entries.to_a
      assert_empty result.tickets
    end

    test "excludes records from other projects with the same tag" do
      project = create_project(key: "quiz-context-project-a")
      other_project = create_project(key: "quiz-context-project-b")
      entry = project.find_or_create_main_quiz!.entries.create!(question: "A?", answer: "A")
      other_entry = other_project.find_or_create_main_quiz!.entries.create!(question: "B?", answer: "B")

      entry.tag_with!("shared")
      other_entry.tag_with!("shared")

      result = RetrievalQuery.new(project: project, tags: ["shared"]).call

      assert_equal [entry], result.quiz_entries.to_a
    end

    test "does not retrieve candidate mode or strategy metadata as context ranking material" do
      project = create_project(key: "quiz-context-candidate-metadata")
      quiz = project.find_or_create_main_quiz!
      quiz.update!(mode: "fast")
      quiz.add_candidate!(
        question: "Candidate?",
        tags: ["candidate-only"],
        prompt_intent: {
          "kind" => "quiz_question",
          "metadata" => {
            "routing_state" => {
              "mode" => "fast",
              "generation_strategy" => "single_candidate"
            }
          }
        }
      )
      entry = quiz.entries.create!(question: "Activated?", answer: "Answered.")
      entry.tag_with!("activated-only")

      candidate_result = RetrievalQuery.new(project: project, tags: ["candidate-only"]).call
      activated_result = RetrievalQuery.new(project: project, tags: ["activated-only"]).call

      assert_empty candidate_result.quiz_entries
      assert_empty candidate_result.taggings
      assert_equal [entry], activated_result.quiz_entries.to_a
    end
  end
end
