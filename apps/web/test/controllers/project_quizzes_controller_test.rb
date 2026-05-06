require "test_helper"

class ProjectQuizzesControllerTest < ActionDispatch::IntegrationTest
  def create_admin_user!
    User.create!(
      email_address: "quiz-owner@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
  end

  test "index requires authentication" do
    project = create_project(key: "quiz-controller-auth")

    get project_quizzes_path(project)

    assert_redirected_to new_session_path
  end

  test "index renders project quizzes with navigation cards" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "quiz-controller-index")

    get project_quizzes_path(project)

    assert_response :success
    assert_match "Quizzes", response.body
    assert_match "Project Quiz", response.body
    assert_match "artifact-type-card", response.body
    refute_match "Use case", response.body
    refute_match "Open Quiz", response.body
  end

  test "index is scoped to requested current project" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(name: "Visible Quiz Project", key: "quiz-controller-visible")
    other_project = create_project(name: "Hidden Quiz Project", key: "quiz-controller-hidden")
    project_quiz = project.find_or_create_main_quiz!
    project_quiz.entries.create!(question: "Visible project question?", answer: "Visible answer")
    use_case = project.use_cases.create!(name: "Billing")
    use_case_quiz = use_case.find_or_create_quiz!
    use_case_quiz.entries.create!(question: "Visible use case question?", answer: "Use case answer")
    other_quiz = other_project.find_or_create_main_quiz!
    other_quiz.entries.create!(question: "Hidden project question?", answer: "Hidden answer")

    get project_quizzes_path(project)

    assert_response :success
    assert_match "Project: Visible Quiz Project", response.body
    assert_match "Project Quiz", response.body
    assert_match "Visible project question?", response.body
    assert_match "Billing", response.body
    assert_match "Visible use case question?", response.body
    refute_match "Hidden project question?", response.body
  end

  test "opens use case quiz from index" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "quiz-controller-use-case")

    post use_case_project_quizzes_path(project), params: { use_case_name: "Billing Flow" }

    use_case = project.use_cases.find_by!(slug: "billing-flow")
    assert_redirected_to project_quiz_path(project, use_case.quiz, question: assigns_or_query_question, tags: "project-context")
  end

  test "show renders current question without hidden rationale" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "quiz-controller-show")
    quiz = project.find_or_create_main_quiz!

    get project_quiz_path(project, quiz, question: "What matters?", tags: "context")

    assert_response :success
    assert_match "What matters?", response.body
    assert_match "Controls: answer, skip, done, cancel", response.body
    refute_match "rationale", response.body
  end

  test "answer persists entry and redirects with next question" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "quiz-controller-answer")
    quiz = project.find_or_create_main_quiz!

    post answer_project_quiz_path(project, quiz), params: {
      question: "What should agents know?",
      answer: "Keep context concise.",
      tags: "context"
    }

    entry = project.quiz_entries.last
    assert_equal "answered", entry.status
    assert_equal "Keep context concise.", entry.answer
    assert_equal ["context"], entry.tags.map(&:name)
    assert_redirected_to project_quiz_path(project, quiz, question: QuizLoops::QuestionProvider::FALLBACK_QUESTION, tags: "project-context")
  end

  test "skip persists skipped entry" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "quiz-controller-skip")
    quiz = project.find_or_create_main_quiz!

    post skip_project_quiz_path(project, quiz), params: {
      question: "Can this be skipped?",
      tags: "optional"
    }

    entry = project.quiz_entries.last
    assert_equal "skipped", entry.status
    assert_equal "", entry.answer
    assert_equal ["optional"], entry.tags.map(&:name)
  end

  test "done and cancel redirect back to quiz list without permanent closure" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "quiz-controller-terminal")
    quiz = project.find_or_create_main_quiz!

    post done_project_quiz_path(project, quiz), params: { question: "Done?" }
    assert_redirected_to project_quizzes_path(project)

    post cancel_project_quiz_path(project, quiz), params: { question: "Cancel?" }
    assert_redirected_to project_quizzes_path(project)

    get project_quiz_path(project, quiz)
    assert_response :success
  end

  private

  def assigns_or_query_question
    QuizLoops::QuestionProvider::FALLBACK_QUESTION
  end
end
