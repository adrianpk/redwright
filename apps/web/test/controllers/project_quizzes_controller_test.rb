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
    refute_match "projects/#{project.id}/quizzes/project", response.body
    refute_match "Use case", response.body
    refute_match "Open Quiz", response.body
    refute_match "New Quiz", response.body
  end

  test "index is scoped to requested current project" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(name: "Visible Quiz Project", key: "quiz-controller-visible")
    other_project = create_project(name: "Hidden Quiz Project", key: "quiz-controller-hidden")
    project_quiz = project.find_or_create_main_quiz!
    project_quiz.entries.create!(question: "Visible project question?", answer: "Visible answer")
    use_case = create_use_case(project: project, name: "Billing")
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

  test "index exposes new quiz action only for use cases without quizzes" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "quiz-controller-new-use-case")
    untreated = create_use_case(project: project, name: "Billing")
    treated = create_use_case(project: project, name: "Checkout")
    treated.find_or_create_quiz!

    get project_quizzes_path(project)

    assert_response :success
    assert_match "New Quiz", response.body
    assert_match "quiz-new-use-case-menu", response.body
    assert_match "quiz-new-use-case-option", response.body
    assert_match "Billing", response.body
    assert_select ".quiz-new-use-case-option", text: "Billing"
    assert_select ".quiz-new-use-case-option", text: "Checkout", count: 0

    post use_case_project_quizzes_path(project), params: { use_case_id: untreated.id }

    assert_redirected_to project_quiz_path(project, untreated.reload.quiz)

    get project_quizzes_path(project)

    assert_response :success
    refute_match "New Quiz", response.body
  end

  test "opens use case quiz from index" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "quiz-controller-use-case")

    post use_case_project_quizzes_path(project), params: { use_case_name: "Billing Flow" }

    use_case = project.use_cases.find_by!(slug: "billing-flow")
    assert_redirected_to project_quiz_path(project, use_case.quiz)
    assert_equal QuizLoops::QuestionProvider::FALLBACK_QUESTION, use_case.quiz.current_question
    assert_equal ["project-context"], use_case.quiz.current_tags
  end

  test "show renders backend current question without hidden rationale" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "quiz-controller-show")
    quiz = project.find_or_create_main_quiz!

    get project_quiz_path(project, quiz, question: "Ignored URL question", tags: "ignored")

    assert_response :success
    assert_match QuizLoops::QuestionProvider::FALLBACK_QUESTION, response.body
    assert_no_match "Ignored URL question", response.body
    assert_no_match "Controls: answer, skip, done, cancel", response.body
    assert_match "quiz-action-row", response.body
    assert_select "#quiz-answer-form"
    assert_select "#quiz-answer-form[data-quiz-processing-form]"
    assert_select "#quiz-processing-feedback[hidden] .quiz-processing-dots span", count: 3
    assert_select "#quiz-processing-feedback .quiz-processing-hint", count: 0
    assert_select ".document-artifact-panel[data-quiz-processing-surface]"
    assert_select ".quiz-header-row h1", text: "Project Quiz"
    assert_select ".quiz-header-row .quiz-mode-switch"
    assert_select ".quiz-mode-switch"
    assert_select ".quiz-mode-action.is-active", text: "Deep"
    assert_select ".quiz-mode-action", text: "Fast"
    assert_select "button[form='quiz-answer-form']", text: "Answer"
    assert_select "form[data-quiz-processing-form] button", text: "Skip"
    assert_select "form[data-quiz-processing-form] button", text: "Cancel", count: 0
    assert_select "form[data-quiz-processing-form] button", text: "Done", count: 0
    refute_match "rationale", response.body
  end

  test "show renders fast refill hint when fast queue is empty" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "quiz-controller-fast-refill-hint")
    quiz = project.find_or_create_main_quiz!
    quiz.update!(mode: "fast")

    get project_quiz_path(project, quiz)

    assert_response :success
    assert_select "#quiz-processing-feedback[hidden] .quiz-processing-dots span", count: 3
    assert_select "#quiz-processing-feedback .quiz-processing-hint", text: "Preparing fast loop."
  end

  test "show omits fast refill hint when fast queue has active candidates" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "quiz-controller-fast-refill-hint-queued")
    quiz = project.find_or_create_main_quiz!
    quiz.update!(mode: "fast")
    quiz.add_candidate!(
      question: "What queued fast question should be next?",
      tags: ["fast"],
      prompt_intent: { "kind" => "quiz_question" }
    )

    get project_quiz_path(project, quiz)

    assert_response :success
    assert_select "#quiz-processing-feedback .quiz-processing-hint", count: 0
  end

  test "mode updates quiz mode without changing current question" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "quiz-controller-mode")
    quiz = project.find_or_create_main_quiz!
    quiz.store_current_question!(
      question: "What should remain active?",
      tags: ["mode"],
      prompt_intent: { "kind" => "quiz_question" },
      fallback_reason: "",
      errors: []
    )

    patch mode_project_quiz_path(project, quiz), params: { mode: "fast" }

    assert_redirected_to project_quiz_path(project, quiz)
    assert_equal "fast", quiz.reload.mode
    assert_equal "What should remain active?", quiz.current_question
  end

  test "mode rejects invalid quiz mode" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "quiz-controller-invalid-mode")
    quiz = project.find_or_create_main_quiz!

    patch mode_project_quiz_path(project, quiz), params: { mode: "turbo" }

    assert_redirected_to project_quiz_path(project, quiz)
    assert_equal "deep", quiz.reload.mode
  end

  test "answer persists backend current question and redirects without query payload" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "quiz-controller-answer")
    quiz = project.find_or_create_main_quiz!
    quiz.store_current_question!(
      question: "What should agents know?",
      tags: ["context"],
      prompt_intent: { "kind" => "quiz_question" },
      fallback_reason: "",
      errors: []
    )

    post answer_project_quiz_path(project, quiz), params: {
      question: "Ignored submitted question?",
      answer: "Keep context concise.",
      tags: "ignored"
    }

    entry = project.quiz_entries.last
    assert_equal "answered", entry.status
    assert_equal "What should agents know?", entry.question
    assert_equal "Keep context concise.", entry.answer
    assert_equal ["context"], entry.tags.map(&:name)
    assert_redirected_to project_quiz_path(project, quiz)
  end

  test "skip persists backend current question and redirects without query payload" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "quiz-controller-skip")
    quiz = project.find_or_create_main_quiz!
    quiz.store_current_question!(
      question: "Can this be skipped?",
      tags: ["optional"],
      prompt_intent: { "kind" => "quiz_question" },
      fallback_reason: "",
      errors: []
    )

    post skip_project_quiz_path(project, quiz), params: {
      question: "Ignored skip question?",
      tags: "ignored"
    }

    entry = project.quiz_entries.last
    assert_equal "skipped", entry.status
    assert_equal "Can this be skipped?", entry.question
    assert_equal "", entry.answer
    assert_equal ["optional"], entry.tags.map(&:name)
    assert_redirected_to project_quiz_path(project, quiz)
  end

  test "done and cancel redirect back to quiz list without permanent closure" do
    admin = create_admin_user!
    sign_in_as(admin)
    project = create_project(key: "quiz-controller-terminal")
    quiz = project.find_or_create_main_quiz!
    quiz.store_current_question!(
      question: "Done?",
      tags: ["completion"],
      prompt_intent: { "kind" => "quiz_question" },
      fallback_reason: "",
      errors: []
    )

    post done_project_quiz_path(project, quiz), params: { question: "Ignored done question?", tags: "ignored" }
    assert_redirected_to project_quizzes_path(project)
    assert_nil quiz.reload.current_question

    quiz.store_current_question!(
      question: "Cancel?",
      tags: ["cancellation"],
      prompt_intent: { "kind" => "quiz_question" },
      fallback_reason: "",
      errors: []
    )

    post cancel_project_quiz_path(project, quiz), params: { question: "Ignored cancel question?", tags: "ignored" }
    assert_redirected_to project_quizzes_path(project)
    assert_nil quiz.reload.current_question

    get project_quiz_path(project, quiz)
    assert_response :success
  end

end
