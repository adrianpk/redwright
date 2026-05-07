class ProjectQuizzesController < ApplicationController
  before_action :set_project
  before_action :set_quiz, only: [ :show, :answer, :skip, :done, :cancel ]

  def index
    persist_current_project!(@project)
    ensure_project_quiz
    @quizzes = scoped_quizzes
    @available_use_cases_for_quiz = available_use_cases_for_quiz
  end

  def show
    persist_current_project!(@project)
    current = open_quiz
    @current_question = current.question
    @current_tags = current.tags
    @recent_entries = @quiz.entries.includes(:tags).order(created_at: :desc).limit(6)
  end

  def project
    quiz = @project.find_or_create_main_quiz!
    redirect_to project_quiz_path(@project, quiz)
  end

  def use_case
    use_case = use_case_for_new_quiz
    unless use_case
      redirect_to project_quizzes_path(@project), alert: "Use case is required."
      return
    end

    result = QuizLoops::Runtime.new(project: @project, use_case_name: use_case.name).open
    redirect_to project_quiz_path(@project, result.quiz)
  end

  def answer
    answer = params.require(:answer).to_s.strip
    if answer.empty?
      redirect_to project_quiz_path(@project, @quiz), alert: "Answer is required."
      return
    end

    runtime_for(@quiz).advance!(answer: answer)
    redirect_to project_quiz_path(@project, @quiz), notice: "Answer saved."
  end

  def skip
    runtime_for(@quiz).advance!(answer: "skip")
    redirect_to project_quiz_path(@project, @quiz), notice: "Question skipped."
  end

  def done
    runtime_for(@quiz).advance!(question: params.require(:question), answer: "done", tags: tag_params)
    redirect_to project_quizzes_path(@project), notice: "Quiz stopped as done."
  end

  def cancel
    runtime_for(@quiz).advance!(question: params.require(:question), answer: "cancel", tags: tag_params)
    redirect_to project_quizzes_path(@project), notice: "Quiz cancelled."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_quiz
    @quiz = @project.quizzes.find(params[:id])
  end

  def ensure_project_quiz
    @project.find_or_create_main_quiz!
  end

  def scoped_quizzes
    @project.quizzes.includes(:use_case, entries: :tags).order(:use_case_id, :id)
  end

  def available_use_cases_for_quiz
    @project.use_cases.left_outer_joins(:quiz).where(quizzes: { id: nil }).order(:name, :id)
  end

  def use_case_for_new_quiz
    use_case_id = params[:use_case_id].presence
    return @project.use_cases.find_by(id: use_case_id) if use_case_id

    use_case_name = params[:use_case_name].to_s.strip
    return nil if use_case_name.empty?

    @project.use_cases.find_or_create_by!(name: use_case_name) do |record|
      record.description = "Use case created from quiz scope."
    end
  end

  def open_quiz
    runtime_for(@quiz).open
  end

  def runtime_for(quiz)
    QuizLoops::Runtime.new(project: @project, use_case_name: quiz.use_case&.name)
  end

  def tag_params
    params[:tags].to_s.split(",").map(&:strip).reject(&:blank?)
  end
end
