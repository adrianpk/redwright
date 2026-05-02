class ProjectsController < ApplicationController
  def index
    @projects = Project.order(:name)
  end

  def show
    @project = Project.find(params[:id])
  end

  def new
    @project_form = default_project_form
  end

  def create
    @project_form = project_form_params

    command = ProjectInitialization::Command.new(
      project_name: @project_form[:name],
      directory_name: @project_form[:directory_name],
      repository_input: @project_form[:repository_input],
      guided_alignment: ActiveModel::Type::Boolean.new.cast(@project_form[:guided_alignment])
    )

    orchestration = ProjectInitialization::Orchestrator.new(command: command).call
    case orchestration.status
    when :invalid_command
      @errors = orchestration.errors
      return render :new, status: :unprocessable_entity
    when :repository_resolution_ambiguous
      @errors = {repository_input: "requires clarification"}
      flash.now[:alert] = "Repository input is ambiguous. Use URL, git@host:owner/repo, or owner/repo."
      return render :new, status: :unprocessable_entity
    when :initialization_cancelled
      redirect_to projects_path, notice: "Project initialization cancelled."
      return
    when :repository_resolved
      result = ProjectInitialization::Executor.new(
        command: command,
        resolved_repository: orchestration.repository.slice(:canonical, :source),
        lifecycle: ProjectInitialization::ActiveRecordLifecycle.new
      ).call

      handle_execution_result(result)
      return
    end

    flash.now[:alert] = "Unsupported initialization state: #{orchestration.status}."
    render :new, status: :unprocessable_entity
  end

  private

  def default_project_form
    {
      name: "",
      directory_name: "",
      repository_input: "",
      guided_alignment: true
    }
  end

  def project_form_params
    params.require(:project).permit(:name, :directory_name, :repository_input, :guided_alignment)
  end

  def handle_execution_result(result)
    case result.status
    when :initialization_completed
      project = Project.find(result.project[:id])
      notice = if result.guided_alignment[:requested]
        "Project created. Guided alignment opted in."
      else
        "Project created. Guided alignment skipped by user choice."
      end
      redirect_to project_path(project), notice: notice
    when :initialization_failed
      @errors = {base: result.errors.dig(:initialization, :message)}
      flash.now[:alert] = "Initialization failed and was reconciled."
      render :new, status: :unprocessable_entity
    when :initialization_incomplete
      @errors = {base: result.errors.dig(:initialization, :message)}
      flash.now[:alert] = "Initialization incomplete. Manual reconciliation required."
      render :new, status: :unprocessable_entity
    else
      @errors = {base: "unexpected execution result"}
      render :new, status: :unprocessable_entity
    end
  end
end
