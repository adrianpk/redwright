class UseCasesController < ApplicationController
  before_action :set_project

  def index
    persist_current_project!(@project)
    @use_cases = @project.use_cases.order(created_at: :desc, id: :desc)
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end
end
