class DocumentsController < ApplicationController
  DOCUMENT_TYPE_CARDS = [
    {type: "draft", title: "Drafts"},
    {type: "spec", title: "Specs"},
    {type: "plan_tracker", title: "Plan Trackers"}
  ].freeze

  before_action :set_document, only: [ :show, :edit, :update, :promote ]

  def index
    allowed_types = DOCUMENT_TYPE_CARDS.map { |card| card.fetch(:type) }
    selected_type = params[:type].to_s
    selected_type = "draft" unless allowed_types.include?(selected_type)
    @selected_type = selected_type
    persist_current_project!(current_project) if current_project.present?
    scoped_documents = documents_scope_for(active_project_id)
    @document_type_cards = DOCUMENT_TYPE_CARDS.map { |card| document_type_card(card, scoped_documents) }
    @artifacts = scoped_documents.where(artifact_type: selected_type).order(updated_at: :desc, created_at: :desc)
  end

  def show
    persist_current_project!(@artifact.project)
    @related_artifacts = @artifact.related_artifacts
  end

  def new
    @artifact = Document.new(artifact_type: "draft", editable: true, project: default_project)
    load_document_form_context(@artifact.project_id)
  end

  def create
    @artifact = Document.new(draft_params.merge(artifact_type: "draft", editable: true, project: default_project))
    if @artifact.save
      persist_current_project!(@artifact.project)
      redirect_to document_path(@artifact), notice: "Draft created."
    else
      load_document_form_context(@artifact.project_id)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    if read_only_document?(@artifact)
      redirect_to document_path(@artifact), alert: "Only drafts are editable in phase one."
      return
    end

    load_document_form_context(@artifact.project_id)
  end

  def update
    if read_only_document?(@artifact)
      redirect_to document_path(@artifact), alert: "Only drafts are editable in phase one."
      return
    end

    if @artifact.update(draft_params)
      redirect_to document_path(@artifact), notice: "Draft updated."
    else
      load_document_form_context(@artifact.project_id)
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
  rescue DocumentPromotionService::PromotionError => e
    redirect_to document_path(@artifact), alert: "Promotion failed: #{e.message}"
  end

  private

  def set_document
    @artifact = Document.find(params[:id])
  end

  def active_project_id
    params[:project_id].presence || current_project&.id
  end

  def documents_scope_for(project_id)
    artifacts = Document.all
    artifacts = artifacts.for_project(project_id) if project_id.present?
    artifacts
  end

  def document_type_card(card, scoped_documents)
    documents = scoped_documents
      .where(artifact_type: card.fetch(:type))
      .order(updated_at: :desc, created_at: :desc)
      .limit(6)

    card.merge(preview_lines: documents.map(&:title))
  end

  def draft_params
    params.require(:document).permit(:title, :body, :use_case_id)
  end

  def load_document_form_context(project_id)
    @available_use_cases = UseCase.where(project_id: project_id).order(:name, :id)
  end

  def read_only_document?(document)
    %w[spec plan_tracker].include?(document.artifact_type)
  end

  def default_project
    return current_project if current_project.present?

    Project.find_or_create_by!(root_path: "/workspace/projects/documents") do |project|
      project.name = "Documents"
      project.description = "Default project context for document flows"
      project.repo_url = "https://codeberg.org/acme/documents"
      project.stack_slug = "ruby"
    end
  end
end
