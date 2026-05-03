class ProjectProtocolsController < ApplicationController
  before_action :set_project
  before_action :set_protocol_document, only: [ :show, :edit, :update ]

  def index
    @protocol = @project.protocol
    @protocol_documents = @protocol ? @protocol.documents : []
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

  def set_protocol_document
    @protocol_document = @project.protocol&.documents&.find_by(id: params[:id])
    return if @protocol_document

    redirect_to project_protocols_path(@project), alert: "Protocol document not found."
  end

  def protocol_document_params
    params.require(:project_protocol_document).permit(:title, :body)
  end
end
