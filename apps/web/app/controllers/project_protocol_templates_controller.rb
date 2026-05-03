class ProjectProtocolTemplatesController < ApplicationController
  before_action :require_admin!
  before_action :set_catalog
  before_action :set_template, only: [ :show ]

  def index
    @templates = @catalog.all_templates
    @common_templates = @templates.select(&:common?)
    @stack_templates = @templates.select(&:stack?)
  end

  def show
  end

  private

  def set_catalog
    @catalog = ProjectProtocols::TemplateCatalog.new
  end

  def set_template
    @template = @catalog.find_template(params[:id])
  end
end
