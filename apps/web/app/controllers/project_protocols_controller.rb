class ProjectProtocolsController < ApplicationController
  before_action :set_project
  before_action :set_catalog
  before_action :set_protocol_document, only: [ :show, :edit, :update, :destroy ]

  def index
    @protocol_entries = @catalog.top_level_entries
    @playbook_entries = @catalog.playbook_entries
    @playbook_listing_lines = @playbook_entries.map { |entry| File.basename(entry.path) }
  end

  def playbooks
    @playbook_entries = @catalog.playbook_entries
    @playbooks_index = @catalog.documents.find(&:playbooks_index?)
  end

  def show
  end

  def new
    @protocol_document = ProjectProtocols::FileDocument.new(store: @catalog)
  end

  def create
    @protocol_document = ProjectProtocols::FileDocument.new(store: @catalog)
    @protocol_document.assign_attributes(protocol_document_params)
    document = document_service.create(**protocol_document_params.to_h.symbolize_keys.except(:revision))
    redirect_to project_protocol_path(@project, document), notice: "Protocol created."
  rescue Specifications::Error => error
    render_document_error(error, :new)
  end

  def edit
    redirect_to project_protocol_path(@project, @protocol_document)
  end

  def update
    attributes = protocol_document_params
    @protocol_document = document_service.update(@protocol_document, **attributes.to_h.symbolize_keys)
    respond_to do |format|
      format.json do
        render json: {
          id: @protocol_document.id,
          updated_at: @protocol_document.updated_at&.iso8601,
          revision: @protocol_document.revision,
          agents_revision: @protocol_document.agents_revision
        }
      end
      format.html { redirect_to project_protocol_path(@project, @protocol_document), notice: "Protocol updated." }
    end
  rescue Specifications::Error => error
    @protocol_document.assign_attributes(attributes)
    render_document_error(error, :show)
  end

  def destroy
    redirect_path = @protocol_document.path.start_with?(".agents/playbooks/") ? playbooks_project_protocols_path(@project) : project_protocols_path(@project)
    document_service.delete(@protocol_document, **protocol_document_params.to_h.symbolize_keys.slice(:revision, :agents_revision))
    redirect_to redirect_path, notice: "Protocol deleted."
  rescue Specifications::Error => error
    render_document_error(error, :show)
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_catalog
    @catalog = @project.protocol_files
  end

  def set_protocol_document
    @protocol_document = @catalog.find(params[:id])
  end

  def protocol_document_params
    params.require(:protocol_document).permit(:name, :description, :body, :revision, :agents_revision)
  end

  def document_service
    ProjectProtocols::Documents.new(store: @catalog)
  end

  def render_document_error(error, view)
    @protocol_document.errors.add(:base, error.message)
    status = error.code == :conflict ? :conflict : :unprocessable_entity
    respond_to do |format|
      format.json { render json: {errors: @protocol_document.errors.full_messages}, status: status }
      format.html { render view, status: status }
    end
  end

end
