class ProjectHarnessSettingsController < ApplicationController
  before_action :set_project

  def show
    @snapshot = @settings.snapshot
    respond_to do |format|
      format.html
      format.json { render json: @snapshot }
    end
  end

  def update
    values = params.require(:harness_setting)
    unless values.is_a?(ActionController::Parameters) && (values.keys - Harnesses::Settings::FIELDS).empty?
      raise Harnesses::Error.new("Only prepared profile choices and selection metadata are accepted.", code: :invalid_request)
    end
    result = @settings.change!(actor: current_user, attributes: values.permit(*Harnesses::Settings::FIELDS).to_h)
    respond_to do |format|
      format.html { redirect_to project_harness_setting_path(@project), notice: "Harness selection saved." }
      format.json { render json: result }
    end
  rescue ActionController::ParameterMissing
    render_error(Harnesses::Error.new("A harness selection is required.", code: :invalid_request))
  rescue Harnesses::Error => error
    render_error(error)
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
    @settings = Harnesses::Settings.new(project: @project)
  end

  def render_error(error)
    status = %i[conflict stale_revision].include?(error.code) ? :conflict : :unprocessable_entity
    respond_to do |format|
      format.json { render json: {error: error.code, message: error.message}, status: status }
      format.html do
        @snapshot = @settings.snapshot
        @selection_error = error.message
        render :show, status: status
      end
    end
  end
end
