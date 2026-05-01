class DocumentArtifactsController < ApplicationController
  before_action :set_artifact, only: [ :show, :edit, :update, :promote ]

  def index
    @artifacts = DocumentArtifact.where(artifact_type: "draft").order(updated_at: :desc, created_at: :desc)
  end

  def show
  end

  def new
    @artifact = DocumentArtifact.new(artifact_type: "draft", editable: true)
  end

  def create
    @artifact = DocumentArtifact.new(draft_params.merge(artifact_type: "draft", editable: true))
    if @artifact.save
      redirect_to document_artifact_path(@artifact), notice: "Draft created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    if @artifact.artifact_type != "draft"
      redirect_to document_artifact_path(@artifact), alert: "Only drafts are editable in phase one."
      return
    end
  end

  def update
    if @artifact.artifact_type != "draft"
      redirect_to document_artifact_path(@artifact), alert: "Only drafts are editable in phase one."
      return
    end

    if @artifact.update(draft_params)
      redirect_to document_artifact_path(@artifact), notice: "Draft updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def promote
    if @artifact.artifact_type != "draft"
      redirect_to document_artifact_path(@artifact), alert: "Only drafts can be promoted."
      return
    end

    spec = DocumentArtifactPromotionService.new(draft: @artifact).call
    redirect_to document_artifact_path(spec), notice: "Draft promoted to spec."
  rescue StandardError => e
    redirect_to document_artifact_path(@artifact), alert: "Promotion failed: #{e.message}"
  end

  private

  def set_artifact
    @artifact = DocumentArtifact.find(params[:id])
  end

  def draft_params
    params.require(:document_artifact).permit(:title, :body)
  end
end
