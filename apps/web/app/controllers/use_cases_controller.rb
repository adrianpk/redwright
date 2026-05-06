class UseCasesController < ApplicationController
  before_action :set_project
  before_action :set_use_case, only: [ :edit, :update ]

  def index
    persist_current_project!(@project)
    @use_cases = @project.use_cases.order(created_at: :desc, id: :desc)
  end

  def new
    @use_case = @project.use_cases.new
  end

  def create
    @use_case = @project.use_cases.new(use_case_params)
    if @use_case.save
      persist_current_project!(@project)
      redirect_to project_use_cases_path(@project), notice: "Use case created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @use_case.update(use_case_params)
      persist_current_project!(@project)
      redirect_to project_use_cases_path(@project), notice: "Use case updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_use_case
    @use_case = @project.use_cases.find_by!(slug: params[:slug])
  end

  def use_case_params
    params.require(:use_case).permit(:name, :description)
  end
end
