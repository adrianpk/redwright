class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  helper_method :current_user, :navigation_project

  private

  def current_user
    Current.user
  end

  def navigation_project
    return @project if defined?(@project) && @project.present?
    return @protocol_document.project_protocol.project if defined?(@protocol_document) && @protocol_document.present?
    return @template.project if defined?(@template) && @template.respond_to?(:project) && @template.project.present?
    return @document.project if defined?(@document) && @document.respond_to?(:project) && @document.project.present?

    nil
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
