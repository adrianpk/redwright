class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  helper_method :current_user, :navigation_project, :current_project, :available_projects,
                :board_navigation_path, :documents_navigation_path, :quizzes_navigation_path

  private

  def current_user
    Current.user
  end

  def current_project
    return navigation_project if navigation_project.present?

    stored_project_id = session[:current_project_id]
    project = stored_project_id.present? ? Project.find_by(id: stored_project_id) : nil
    project ||= available_projects.first
    session[:current_project_id] = project.id if project.present? && stored_project_id != project.id
    project
  end

  def available_projects
    @available_projects ||= Project.order(:name, :id)
  end

  def navigation_project
    return @project if defined?(@project) && @project.present?
    return @protocol_document.project_protocol.project if defined?(@protocol_document) && @protocol_document.present?
    return @template.project if defined?(@template) && @template.respond_to?(:project) && @template.project.present?
    return @document.project if defined?(@document) && @document.respond_to?(:project) && @document.project.present?

    nil
  end

  def board_navigation_path
    return boards_path unless current_project

    current_project.boards_scope.first ? board_path(current_project.boards_scope.first) : boards_path
  end

  def documents_navigation_path(**params)
    return documents_path(**params) unless current_project

    documents_path({ project_id: current_project.id }.merge(params))
  end

  def quizzes_navigation_path
    return projects_path unless current_project

    project_quizzes_path(current_project)
  end

  def persist_current_project!(project)
    session[:current_project_id] = project.id
  end

  def require_admin!
    return if current_user&.admin?

    respond_to do |format|
      format.turbo_stream { head :forbidden }
      format.json { render json: { error: "forbidden" }, status: :forbidden }
      format.html { redirect_to root_path, alert: "Admin role required." }
    end
  end
end
