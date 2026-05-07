require "test_helper"

class QuizTest < ActiveSupport::TestCase
  test "allows one project level quiz per project" do
    project = create_project(key: "quiz-project-main")
    project.quizzes.create!(name: "Project Quiz")
    duplicate = project.quizzes.new(name: "Duplicate Project Quiz")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:project_id], "has already been taken"
  end

  test "allows one quiz per project use case" do
    project = create_project(key: "quiz-use-case-main")
    use_case = create_use_case(project: project, name: "Checkout")
    project.quizzes.create!(use_case: use_case, name: "Checkout Quiz")
    duplicate = project.quizzes.new(use_case: use_case, name: "Duplicate Checkout Quiz")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:use_case_id], "has already been taken"
  end

  test "allows project quiz and use case quiz in the same project" do
    project = create_project(key: "quiz-project-and-use-case")
    use_case = create_use_case(project: project, name: "Checkout")

    project_quiz = project.quizzes.create!(name: "Project Quiz")
    use_case_quiz = project.quizzes.create!(use_case: use_case, name: "Checkout Quiz")

    assert_equal project_quiz, project.main_quiz
    assert_equal use_case_quiz, use_case.quiz
  end

  test "scopes project-level and use-case quizzes separately" do
    project = create_project(key: "quiz-scope-separation")
    billing = create_use_case(project: project, name: "Billing")
    checkout = create_use_case(project: project, name: "Checkout")
    project_quiz = project.quizzes.create!(name: "Project Quiz")
    billing_quiz = project.quizzes.create!(use_case: billing, name: "Billing Quiz")
    checkout_quiz = project.quizzes.create!(use_case: checkout, name: "Checkout Quiz")

    assert_equal [project_quiz.id], project.quizzes.project_level.pluck(:id)
    assert_equal [billing_quiz.id], project.quizzes.for_use_case(billing.id).pluck(:id)
    assert_equal [checkout_quiz.id], project.quizzes.for_use_case(checkout.id).pluck(:id)
  end

  test "rejects use case from another project" do
    project = create_project(key: "quiz-project-owner")
    other_project = create_project(key: "quiz-other-owner")
    other_use_case = create_use_case(project: other_project, name: "External")
    quiz = project.quizzes.new(use_case: other_use_case, name: "Invalid Quiz")

    assert_not quiz.valid?
    assert_includes quiz.errors[:use_case], "must belong to the same project"
  end

  test "find_or_create helpers preserve cardinality" do
    project = create_project(key: "quiz-helper-project")
    use_case = create_use_case(project: project, name: "Support")

    assert_equal project.find_or_create_main_quiz!, project.find_or_create_main_quiz!
    assert_equal use_case.find_or_create_quiz!, use_case.find_or_create_quiz!
  end
end
