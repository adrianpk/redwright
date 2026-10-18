class DocumentsController < ApplicationController
  before_action :set_project
  before_action :reconcile
  before_action :set_document, only: [:show, :edit, :update, :approve]
  rescue_from Specifications::Error, with: :document_error

  def index
    @artifacts = @project.documents.specifications.order(source_modified_at: :desc, id: :desc)
    @available_use_cases = @project.use_cases.order(:name)
  end

  def show
    @related_artifacts = @artifact.related_artifacts.select { |_, document| document.specification? }
  end

  def new
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
      load_form
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form
  end

  def update
    params.require(:document).require(:revision)
    @artifact.assign_attributes(document_params)
    @artifact.status = params[:approval] == "approved" ? "approved" : "draft"
    if @artifact.save
      redirect_to document_path(@artifact), notice: "Specification saved."
    else
      load_form
      render :edit, status: :unprocessable_entity
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
    @available_use_cases = @project.use_cases.order(:name)
  end

  def document_error(error)
    render plain: error.message, status: error.code == :conflict ? :conflict : :unprocessable_entity
  end
end
