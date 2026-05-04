class ProjectProtocolsController < ApplicationController
  before_action :set_project
  before_action :set_catalog
  before_action :set_protocol_document, only: [ :show, :edit, :update ]

  def index
    @protocol_entries = @catalog.top_level_entries
  end

  def playbooks
    @playbook_entries = @catalog.playbook_entries
  end

  def create
    entry = @catalog.find_expected_entry!(params.require(:key))
    protocol = @project.protocol || @project.create_protocol!(status: "draft")
    document = protocol.documents.find_by(key: entry.key)

    unless document
      document = protocol.documents.create!(
        key: entry.key,
        path: entry.path,
        title: entry.title,
        layer: entry.layer,
        position: entry.position,
        body: entry.body,
        provenance: {"source" => "web_protocols_create"}
      )
    end

    redirect_to(entry.playbooks_index? ? playbooks_project_protocols_path(@project) : edit_project_protocol_path(@project, document), notice: "Protocol created.")
  end

  def show
  end

  def edit
  end

  def update
    if @protocol_document.update(protocol_document_params)
      redirect_to project_protocol_path(@project, @protocol_document), notice: "Protocol updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_catalog
    @catalog = ProjectProtocols::IndexCatalog.new(project: @project)
  end

  def set_protocol_document
    @protocol_document = @project.protocol&.documents&.find_by(id: params[:id])
    return if @protocol_document

    redirect_to project_protocols_path(@project), alert: "Protocol document not found."
  end

  def protocol_document_params
    params.require(:project_protocol_document).permit(:title, :body)
  end
end
