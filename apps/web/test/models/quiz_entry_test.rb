require "test_helper"

class QuizEntryTest < ActiveSupport::TestCase
  test "stores question and answer together" do
    project = create_project(key: "quiz-entry-tuple")
    quiz = project.find_or_create_main_quiz!

    entry = quiz.entries.create!(question: "What matters?", answer: "Fast feedback.")

    assert_equal "What matters?", entry.question
    assert_equal "Fast feedback.", entry.answer
    assert_equal "answered", entry.status
  end

  test "denormalizes project and use case from quiz" do
    project = create_project(key: "quiz-entry-scope")
    use_case = project.use_cases.create!(name: "Billing")
    quiz = use_case.find_or_create_quiz!

    entry = quiz.entries.create!(question: "What is the billing rule?", answer: "Invoices are monthly.")

    assert_equal project.id, entry.project_id
    assert_equal use_case.id, entry.use_case_id
  end

  test "rejects project scope mismatch" do
    project = create_project(key: "quiz-entry-project")
    other_project = create_project(key: "quiz-entry-other-project")
    quiz = project.find_or_create_main_quiz!
    entry = quiz.entries.new(project: other_project, question: "Question", answer: "Answer")

    assert_not entry.valid?
    assert_includes entry.errors[:project], "must match quiz project"
  end

  test "rejects use case scope mismatch" do
    project = create_project(key: "quiz-entry-use-case")
    use_case = project.use_cases.create!(name: "Billing")
    other_use_case = project.use_cases.create!(name: "Support")
    quiz = use_case.find_or_create_quiz!
    entry = quiz.entries.new(use_case: other_use_case, question: "Question", answer: "Answer")

    assert_not entry.valid?
    assert_includes entry.errors[:use_case], "must match quiz use case"
  end

  test "allows skipped entry without answer" do
    project = create_project(key: "quiz-entry-skipped")
    quiz = project.find_or_create_main_quiz!

    entry = quiz.entries.create!(question: "What can be skipped?", status: "skipped")

    assert entry.skipped?
    assert_equal "", entry.answer
  end

  test "requires answer for answered entry" do
    project = create_project(key: "quiz-entry-answer-required")
    quiz = project.find_or_create_main_quiz!
    entry = quiz.entries.new(question: "What is required?", status: "answered")

    assert_not entry.valid?
    assert_includes entry.errors[:answer], "can't be blank"
  end

  test "tags entry with normalized reusable tags" do
    project = create_project(key: "quiz-entry-tags")
    quiz = project.find_or_create_main_quiz!
    entry = quiz.entries.create!(question: "What is important?", answer: "Clear context.")

    tags = entry.tag_with!(" Context Quality ", "context-quality")

    assert_equal ["context-quality"], tags.uniq.map(&:name)
    assert_equal ["context-quality"], entry.tags.map(&:name)
    assert_equal project.id, entry.taggings.first.project_id
  end
end
