class ProjectProtocolTemplatesController < ApplicationController
  before_action :require_admin!
  before_action :set_catalog
  before_action :set_template, only: [ :show, :playbooks, :create_document ]

  def index
  end

  def common
    @template = @catalog.common_template
    @entries = ProjectProtocols::TemplateSetCatalog.new(template: @template).top_level_entries
    render :show
  end

  def common_playbooks
    @template = @catalog.common_template
    @playbook_entries = ProjectProtocols::TemplateSetCatalog.new(template: @template).playbook_entries
  end

  def stacks
    @stack_templates = @catalog.stack_template_sets
  end

  def new_stack
    @template = ProjectProtocolTemplate.new(template_kind: "stack", status: "active")
  end

  def create_stack
    @template = @catalog.create_stack_template!(stack_key: stack_template_params.fetch(:key), name: stack_template_params[:name])
    redirect_to protocol_template_path(@template), notice: "Stack protocol template created."
  rescue ActiveRecord::RecordInvalid
    @template = ProjectProtocolTemplate.new(template_kind: "stack", key: stack_template_params[:key], name: stack_template_params[:name], status: "active")
    @template.errors.add(:key, "is invalid or already taken")
    render :new_stack, status: :unprocessable_entity
  end

  def show
    @entries = ProjectProtocols::TemplateSetCatalog.new(template: @template).top_level_entries
  end

  def playbooks
    @playbook_entries = ProjectProtocols::TemplateSetCatalog.new(template: @template).playbook_entries
  end

  def create_document
    entry = ProjectProtocols::TemplateSetCatalog.new(template: @template).createable_entry!(params.require(:key))
    document = @template.documents.find_by(key: entry.key)

    unless document
      document = @template.documents.create!(
        key: entry.key,
        path: entry.path,
        title: entry.title,
        layer: entry.layer,
        position: entry.position,
        body: entry.body
      )
    end

    redirect_to entry.playbooks_index? ? playbooks_protocol_template_path(@template) : edit_protocol_template_document_path(@template, document), notice: "Protocol template entry created."
  end

  private

  def set_catalog
    @catalog = ProjectProtocols::TemplateCatalog.new
  end

  def set_template
    @template = @catalog.find_template(params[:id])
  end

  def stack_template_params
    params.require(:project_protocol_template).permit(:key, :name)
  end
end
