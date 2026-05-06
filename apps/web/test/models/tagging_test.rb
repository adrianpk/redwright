require "test_helper"

class TaggingTest < ActiveSupport::TestCase
  test "assigns project and use case scope from quiz entry" do
    project = create_project(key: "tagging-entry-scope")
    use_case = create_use_case(project: project, name: "Billing")
    quiz = use_case.find_or_create_quiz!
    entry = quiz.entries.create!(question: "What matters?", answer: "Monthly invoices.")
    tag = Tag.find_or_create_normalized!("Billing")

    tagging = entry.taggings.create!(tag: tag)

    assert_equal project, tagging.project
    assert_equal use_case, tagging.use_case
  end

  test "prevents duplicate taggings for the same record" do
    project = create_project(key: "tagging-entry-duplicate")
    quiz = project.find_or_create_main_quiz!
    entry = quiz.entries.create!(question: "What matters?", answer: "Fast feedback.")
    tag = Tag.find_or_create_normalized!("feedback")
    entry.taggings.create!(tag: tag)

    duplicate = entry.taggings.new(tag: tag)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:tag_id], "has already been taken"
  end

  test "rejects project scope mismatch" do
    project = create_project(key: "tagging-project")
    other_project = create_project(key: "tagging-other-project")
    quiz = project.find_or_create_main_quiz!
    entry = quiz.entries.create!(question: "Question", answer: "Answer")
    tag = Tag.find_or_create_normalized!("scope")

    tagging = entry.taggings.new(tag: tag, project: other_project)

    assert_not tagging.valid?
    assert_includes tagging.errors[:project], "must match taggable project"
  end

  test "queries by project use case and normalized tag name" do
    project = create_project(key: "tagging-query")
    use_case = create_use_case(project: project, name: "Checkout")
    quiz = use_case.find_or_create_quiz!
    entry = quiz.entries.create!(question: "What is the checkout rule?", answer: "Guest checkout is allowed.")
    other_entry = project.find_or_create_main_quiz!.entries.create!(question: "What is global?", answer: "Keep it simple.")

    entry.tag_with!("Checkout", "UX")
    other_entry.tag_with!("Ops")

    result = Tagging
      .for_project(project)
      .for_use_case(use_case)
      .with_tag_names("checkout")
      .map(&:taggable)

    assert_equal [entry], result
  end
end
