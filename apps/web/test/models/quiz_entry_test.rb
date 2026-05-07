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
    use_case = create_use_case(project: project, name: "Billing")
    quiz = use_case.find_or_create_quiz!

    entry = quiz.entries.create!(question: "What is the billing rule?", answer: "Invoices are monthly.")

    assert_equal project.id, entry.project_id
    assert_equal use_case.id, entry.use_case_id
  end

  test "project-level quiz entries remain project-level" do
    project = create_project(key: "quiz-entry-project-level")
    quiz = project.find_or_create_main_quiz!

    entry = quiz.entries.create!(question: "What applies across the project?", answer: "General constraints.")

    assert_equal project.id, entry.project_id
    assert_nil entry.use_case_id
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
    use_case = create_use_case(project: project, name: "Billing")
    other_use_case = create_use_case(project: project, name: "Support")
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

  test "candidate questions do not create entries or tags until activated and answered" do
    project = create_project(key: "quiz-entry-candidate-lifecycle")
    quiz = project.find_or_create_main_quiz!

    candidate = quiz.add_candidate!(
      question: "Which fast path is useful?",
      tags: ["Fast Path"],
      prompt_intent: {"kind" => "quiz_question"},
      parent_id: "root",
      branch_key: "a"
    )

    assert_equal 0, quiz.entries.count
    assert_equal 0, Tag.where(name: "fast-path").count

    activated = quiz.activate_candidate!(candidate.fetch("id"))
    entry = quiz.entries.create!(question: quiz.current_question, answer: "Use it when explicit context is enough.")
    entry.tag_with!(quiz.current_tags)

    assert_equal candidate.fetch("id"), activated.fetch("id")
    assert_equal "Which fast path is useful?", entry.question
    assert_equal ["fast-path"], entry.tags.map(&:name)
  end

  test "activating a candidate prunes active siblings without tagging them" do
    project = create_project(key: "quiz-entry-candidate-pruning")
    quiz = project.find_or_create_main_quiz!
    selected = quiz.add_candidate!(question: "Selected?", tags: ["Selected"], prompt_intent: {}, parent_id: "root", branch_key: "a")
    discarded = quiz.add_candidate!(question: "Discarded?", tags: ["Discarded"], prompt_intent: {}, parent_id: "root", branch_key: "b")

    quiz.activate_candidate!(selected.fetch("id"))

    candidates = quiz.reload.candidate_questions.index_by { |candidate| candidate.fetch("id") }
    assert_equal "activated", candidates.fetch(selected.fetch("id")).fetch("status")
    assert_equal "discarded", candidates.fetch(discarded.fetch("id")).fetch("status")
    assert_equal "sibling_pruned", candidates.fetch(discarded.fetch("id")).fetch("discard_reason")
    assert_equal 0, Tag.where(name: "discarded").count
  end
end
