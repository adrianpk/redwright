class ProjectProtocolTemplateDocumentsController < ApplicationController
  before_action :require_admin!
  before_action :set_template
  before_action :set_document

  def edit
  end

  def update
    attributes = params.require(:protocol_document).permit(:body, :revision)
    if @document.update(body: attributes[:body], revision: attributes[:revision])
      redirect_to protocol_template_path(@template), notice: "Protocol template updated."
    else
      render :edit, status: :conflict
    end
  end

  def destroy
    @document.destroy!
    redirect_to protocol_template_path(@template), notice: "Protocol template file deleted."
  end

  private

  def set_template
    @template = ProjectProtocols::TemplateCatalog.new.find_template(params[:protocol_template_id])
  end

  def set_document
    @document = @template.files.find(params[:id])
  end
end
