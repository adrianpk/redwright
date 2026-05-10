class ProjectDumpsController < ApplicationController
  before_action :set_project
  before_action :set_dump, only: [ :show, :append, :done, :cancel, :curate ]

  def index
    persist_current_project!(@project)
    @dumps = scoped_dumps
    @available_use_cases = @project.use_cases.order(:name, :id)
  end

  def create
    result = DumpLoops::Runtime.new(
      project: @project,
      use_case_name: dump_scope_params[:use_case_name],
      title: dump_scope_params[:title]
    ).open

    redirect_to project_dump_path(@project, result.dump)
  end

  def show
    persist_current_project!(@project)
    @entries = @dump.entries.ordered
  end

  def append
    raw_input = params.require(:raw_input).to_s.strip
    if raw_input.empty?
      redirect_to project_dump_path(@project, @dump), alert: "Dump entry is required."
      return
    end

    result = DumpLoops::Runtime.new(project: @project, dump: @dump).append!(raw_input: raw_input)
    if result.ok?
      redirect_to project_dump_path(@project, @dump), notice: "Dump entry captured."
    else
      redirect_to project_dump_path(@project, @dump), alert: result.errors.join(", ")
    end
  end

  def done
    DumpLoops::Runtime.new(project: @project, dump: @dump).done!
    redirect_to project_dump_path(@project, @dump), notice: "Dump capture completed."
  end

  def cancel
    DumpLoops::Runtime.new(project: @project, dump: @dump).cancel!
    redirect_to project_dumps_path(@project), notice: "Dump capture cancelled."
  end

  def curate
    DumpLoops::Runtime.new(project: @project, dump: @dump).curate!
    redirect_to project_dump_path(@project, @dump), notice: "Dump curated."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_dump
    @dump = @project.dumps.find_by!(slug: params[:id])
  end

  def scoped_dumps
    @project.dumps.includes(:use_case, :entries).order(updated_at: :desc, created_at: :desc)
  end

  def dump_scope_params
    {
      title: params[:title].to_s.strip.presence,
      use_case_name: params[:use_case_name].to_s.strip.presence
    }
  end
end
