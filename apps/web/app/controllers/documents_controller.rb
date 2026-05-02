class DocumentsController < ApplicationController
  before_action :set_document, only: [ :show, :edit, :update, :promote ]

  def index
    allowed_types = %w[draft spec plan_tracker]
    selected_type = params[:type].to_s
    selected_type = "draft" unless allowed_types.include?(selected_type)
    @selected_type = selected_type
    artifacts = Document.where(artifact_type: selected_type)
    artifacts = artifacts.for_project(params[:project_id]) if params[:project_id].present?
    @artifacts = artifacts.order(updated_at: :desc, created_at: :desc)
  end

  def show
    @related_artifacts = @artifact.related_artifacts
  end

  def new
    @artifact = Document.new(artifact_type: "draft", editable: true, project: default_project)
  end

  def create
    @artifact = Document.new(draft_params.merge(artifact_type: "draft", editable: true, project: default_project))
    if @artifact.save
      redirect_to document_path(@artifact), notice: "Draft created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    if read_only_document?(@artifact)
      redirect_to document_path(@artifact), alert: "Only drafts are editable in phase one."
      return
    end
  end

  def update
    if read_only_document?(@artifact)
      redirect_to document_path(@artifact), alert: "Only drafts are editable in phase one."
      return
    end

    if @artifact.update(draft_params)
      redirect_to document_path(@artifact), notice: "Draft updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def promote
    if @artifact.artifact_type != "draft"
      redirect_to document_path(@artifact), alert: "Only drafts can be promoted."
      return
    end

    spec = DocumentPromotionService.new(draft: @artifact).call
    redirect_to document_path(spec), notice: "Draft promoted to spec."
  rescue StandardError => e
    redirect_to document_path(@artifact), alert: "Promotion failed: #{e.message}"
  end

  private

  def set_document
    @artifact = Document.find(params[:id])
  end

  def draft_params
    params.require(:document).permit(:title, :body)
  end

  def read_only_document?(document)
    %w[spec plan_tracker].include?(document.artifact_type)
  end

  def default_project
    Project.find_or_create_by!(root_path: "/workspace/projects/documents") do |project|
      project.name = "Documents"
      project.description = "Default project context for document flows"
      project.repo_url = "https://codeberg.org/acme/documents"
      project.stack_slug = "ruby"
    end
  end
end
