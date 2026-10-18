class ProjectProtocolTemplatesController < ApplicationController
  before_action :require_admin!
  before_action :set_catalog
  before_action :set_template, only: [:show, :playbooks, :create_document]

  def index
  end

  def common
    @template = @catalog.common_template
    @entries = @template.files.top_level_entries
    render :show
  end

  def common_playbooks
    @template = @catalog.common_template
    @playbook_entries = @template.files.playbook_entries
  end

  def stacks
    @stack_templates = @catalog.stack_template_sets
  end

  def new_stack
    @stack_key = ""
  end

  def create_stack
    @stack_key = params.require(:protocol_template).fetch(:key)
    @template = @catalog.create_stack_template!(stack_key: @stack_key)
    redirect_to protocol_template_path(@template), notice: "Stack protocol template created."
  rescue ArgumentError => error
    @error = error.message
    render :new_stack, status: :unprocessable_entity
  end

  def show
    @entries = @template.files.top_level_entries
  end

  def playbooks
    @playbook_entries = @template.files.playbook_entries
  end

  def create_document
    path = params.require(:path)
    document = @template.files.create(path, "# #{File.basename(path, '.md').titleize}\n")
    redirect_to edit_protocol_template_document_path(@template, document), notice: "Protocol template file created."
  rescue ArgumentError, Errno::EEXIST => error
    redirect_to protocol_template_path(@template), alert: error.message
  end

  private

  def set_catalog
    @catalog = ProjectProtocols::TemplateCatalog.new
  end

  def set_template
    @template = @catalog.find_template(params[:id])
  end
end
