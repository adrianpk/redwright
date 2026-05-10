class ProjectConversationsController < ApplicationController
  before_action :set_project

  def show
    persist_current_project!(@project)
    @dump_count = @project.dumps.count
    @quiz_count = @project.quizzes.count
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end
end
