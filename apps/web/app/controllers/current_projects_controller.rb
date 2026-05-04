class CurrentProjectsController < ApplicationController
  def update
    project = Project.find(params.require(:project_id))
    persist_current_project!(project)

    redirect_back fallback_location: board_navigation_path
  end
end
