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

    setup_result = ProjectInitialization::SetupSessionRunner.new(
      command: command,
      actor_identifier: setup_actor_identifier,
      request_id: request.uuid,
      source_channel: "web"
    ).call

    case setup_result.status
    when :invalid_command
      @errors = setup_result.errors
      return render :new, status: :unprocessable_entity
    when :repository_resolution_ambiguous
      @errors = {repository_input: "requires clarification"}
      flash.now[:alert] = "Repository input is ambiguous. Use URL, git@host:owner/repo, or owner/repo."
      return render :new, status: :unprocessable_entity
    when :initialization_cancelled
      redirect_to projects_path, notice: "Project initialization cancelled."
      return
    when :initialization_completed
      handle_execution_result(setup_result)
      return
    end

    flash.now[:alert] = "Unsupported initialization state: #{setup_result.status}."
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

  def setup_actor_identifier
    current_user&.email_address || "anonymous-web-user"
  end

  def handle_execution_result(result)
    case result.status
    when :initialization_completed
      project = Project.find(result.project[:id])
      notice = if result.guided_alignment[:setup_state] == "collecting_alignment"
        "Project created. Guided alignment is ready to continue."
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
