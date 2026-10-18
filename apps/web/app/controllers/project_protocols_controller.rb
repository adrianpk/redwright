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

  def edit
    redirect_to project_protocol_path(@project, @protocol_document)
  end

  def update
    attributes = protocol_document_params
    if @protocol_document.update(body: attributes[:body], revision: attributes[:revision])
      respond_to do |format|
        format.json do
          render json: {
            id: @protocol_document.id,
            updated_at: @protocol_document.updated_at&.iso8601,
            revision: @protocol_document.revision
          }
        end
        format.html { redirect_to project_protocol_path(@project, @protocol_document), notice: "Protocol updated." }
      end
    else
      respond_to do |format|
        status = @protocol_document.errors.of_kind?(:base, :stale) ? :conflict : :unprocessable_entity
        format.json { render json: {errors: @protocol_document.errors.full_messages}, status: status }
        format.html { render :show, status: status }
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
    @catalog = @project.protocol_files
  end

  def set_protocol_document
    @protocol_document = @catalog.find(params[:id])
  end

  def protocol_document_params
    params.require(:protocol_document).permit(:body, :revision).with_defaults(revision: nil)
  end

end
