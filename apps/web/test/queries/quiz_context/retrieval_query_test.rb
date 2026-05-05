require "test_helper"

module QuizContext
  class RetrievalQueryTest < ActiveSupport::TestCase
    test "retrieves quiz entries and tickets by shared project use case and tag" do
      project = create_project(key: "quiz-context-retrieval")
      board = create_board(project_key: "quiz-context-retrieval-board", project: project)
      column = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
      use_case = project.use_cases.create!(name: "Billing")
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
  end
end
