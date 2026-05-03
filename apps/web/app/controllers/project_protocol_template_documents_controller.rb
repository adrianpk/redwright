class ProjectProtocolTemplateDocumentsController < ApplicationController
  before_action :require_admin!
  before_action :set_template
  before_action :set_document, only: [ :edit, :update ]

  def edit
  end

  def update
    if @document.update(template_document_params)
      redirect_to protocol_template_path(@template), notice: "Protocol template updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_template
    @template = ProjectProtocols::TemplateCatalog.new.find_template(params[:protocol_template_id])
  end

  def set_document
    @document = @template.documents.find(params[:id])
  end

  def template_document_params
    params.require(:project_protocol_template_document).permit(:title, :body)
  end
end
