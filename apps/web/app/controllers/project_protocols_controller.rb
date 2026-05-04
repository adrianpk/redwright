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
  end

  def show
    @body_placeholder = @catalog.find_expected_entry!(@protocol_document.key).body
  end

  def edit
    redirect_to project_protocol_path(@project, @protocol_document)
  end

  def update
    if @protocol_document.update(protocol_document_params)
      respond_to do |format|
        format.json do
          render json: {
            id: @protocol_document.id,
            updated_at: @protocol_document.updated_at&.iso8601
          }
        end
        format.html { redirect_to project_protocol_path(@project, @protocol_document), notice: "Protocol updated." }
      end
    else
      respond_to do |format|
        format.json { render json: {errors: @protocol_document.errors.full_messages}, status: :unprocessable_entity }
        format.html { render :show, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    redirect_path = @protocol_document.path.start_with?(".agents/playbooks/") ? playbooks_project_protocols_path(@project) : project_protocols_path(@project)
    @protocol_document.destroy!
    redirect_to redirect_path, notice: "Protocol deleted."
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
    params.require(:project_protocol_document).permit(:body)
  end

end
