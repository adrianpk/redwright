class CurrentProjectsController < ApplicationController
  def update
    project = Project.find(params.require(:project_id))
    persist_current_project!(project)

    board = project.boards_scope.first
    redirect_to(board ? board_path(board) : projects_path)
  end
end
