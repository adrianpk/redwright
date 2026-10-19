class DocumentsController < ApplicationController
  before_action :set_project
  before_action :reconcile
  before_action :set_document, only: [:show, :edit, :update, :approve, :regenerate, :slice]
  rescue_from Specifications::Error, with: :document_error

  def index
    @artifacts = @project.documents.specifications.order(source_modified_at: :desc, id: :desc)
  end

  def show
    @related_artifacts = @artifact.related_artifacts.select { |_, document| document.specification? }
    @execution_started = Features::Workflow.new(@artifact.use_case).started?
  end

  def new
    @authoring_mode = params[:mode] == "write" ? "write" : "generate"
    @artifact = @project.documents.new(artifact_type: "spec", status: "draft")
    load_form
  end

  def create
    @artifact = @project.documents.new(document_params.except(:revision))
    @artifact.artifact_type = "spec"
    @artifact.status = params[:approval] == "approved" ? "approved" : "draft"
    if @artifact.save
      redirect_to document_path(@artifact), notice: "Specification saved."
    else
      @authoring_mode = "write"
      load_form
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    Features::Workflow.new(@artifact.use_case).ensure_mutable!
    load_form
  end

  def update
    params.require(:document).require(:revision)
    @artifact.revise!(attributes: document_params.except(:revision).merge(status: params[:approval] == "approved" ? "approved" : "draft"), revision: document_params[:revision])
    respond_to do |format|
      format.json do
        render json: {revision: @artifact.source_hash, status: @artifact.status,
          rendered_body: helpers.artifact_markdown(@artifact.body)}
      end
      format.html { redirect_to document_path(@artifact), notice: "Specification saved." }
    end
  rescue ActiveRecord::RecordInvalid => error
    respond_to do |format|
      format.json { render json: {errors: error.record.errors.full_messages}, status: :unprocessable_entity }
      format.html do
        load_form
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def approve
    @artifact.approve!(revision: params.require(:revision))
    redirect_to document_path(@artifact), notice: "Specification approved."
  end

  def generate
    use_case = @project.use_cases.find(params[:use_case_id]) if params[:use_case_id].present?
    specification = Specifications::Generator.new(project: @project, use_case: use_case, feature: params[:feature]).call
    redirect_to document_path(specification), notice: "Specification generated. Review it and approve when ready."
  rescue Specifications::Error => error
    @authoring_mode = "generate"
    @generation_error = error.message
    load_form
    render :new, status: :unprocessable_entity
  end

  def regenerate
    Specifications::Generator.new(project: @project, use_case: @artifact.use_case, feature: params[:feature]).call
    redirect_to document_path(@artifact), notice: "Specification regenerated."
  end

  def slice
    Specifications::Slicing.new(specification: @artifact).call
    redirect_to document_path(@artifact), notice: "Tickets updated."
  end

  private

  def set_project
    record = Document.find(params[:id]) if params[:id]
    @project = record&.project || (Project.find(params[:project_id]) if params[:project_id].present?) || current_project
    raise ActiveRecord::RecordNotFound unless @project
    persist_current_project!(@project)
  end

  def reconcile
    Document.reconcile!(@project)
  end

  def set_document
    @artifact = @project.documents.specifications.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:title, :body, :use_case_id, :revision)
  end

  def load_form
    scope = @project.use_cases.order(:name)
    scope = scope.where.not(id: @project.documents.specifications.select(:use_case_id)) if @artifact&.new_record?
    @available_use_cases = scope
  end

  def document_error(error)
    status = error.code == :conflict ? :conflict : :unprocessable_entity
    respond_to do |format|
      format.json { render json: {errors: [error.message]}, status: status }
      format.html { render plain: error.message, status: status }
    end
  end
end
