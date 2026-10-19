class ProjectDumpsController < ApplicationController
  before_action :set_project
  before_action :set_dump, only: [:show, :update, :curate]
  rescue_from Specifications::Error, with: :document_error

  def index
    persist_current_project!(@project)
    @dumps = @project.dumps.includes(:use_case).order(source_modified_at: :desc, id: :desc)
  end

  def new
    @available_use_cases = @project.use_cases.where.not(id: @project.dumps.where.not(use_case_id: nil).select(:use_case_id)).order(:name)
  end

  def create
    dump = Dumps::Documents.new(@project).open(use_case_name: params[:use_case_name].to_s.strip.presence, title: params[:title].to_s.strip.presence)
    redirect_to project_dump_path(@project, dump)
  end

  def show
    persist_current_project!(@project)
  end

  def update
    attributes = params.require(:dump).permit(:body, :revision, :status)
    raise ActionController::ParameterMissing, :body unless attributes.key?(:body)
    Dumps::Documents.new(@project).update(@dump, body: attributes[:body], revision: attributes[:revision], status: attributes.fetch(:status, @dump.status))
    respond_to do |format|
      format.json do
        render json: {revision: @dump.source_hash, updated_at: @dump.source_modified_at.iso8601,
          status: @dump.status, status_label: @dump.status.humanize, rendered_body: helpers.artifact_markdown(@dump.body)}
      end
      format.html { redirect_to project_dump_path(@project, @dump), notice: "Dump saved." }
    end
  rescue ActiveRecord::RecordInvalid => error
    render json: {errors: error.record.errors.full_messages}, status: :unprocessable_entity
  end

  def curate
    Dumps::Documents.new(@project).curate(@dump, revision: params[:revision])
    redirect_to project_dump_path(@project, @dump), notice: "Dump curated."
  rescue Specifications::Error => error
    redirect_to project_dump_path(@project, @dump), alert: error.message
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
    Dump.reconcile!(@project)
  end

  def set_dump
    @dump = @project.dumps.find_by!(slug: params[:id])
  end

  def document_error(error)
    status = error.code == :conflict ? :conflict : :unprocessable_entity
    respond_to do |format|
      format.json { render json: {errors: [error.message]}, status: status }
      format.html { render plain: error.message, status: status }
    end
  end
end
