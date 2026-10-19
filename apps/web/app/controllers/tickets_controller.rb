class TicketsController < ApplicationController
  before_action :set_ticket, only: [ :edit, :update, :comment, :move, :archive, :destroy ]
  before_action :set_board, only: [ :new, :create, :pick ]
  before_action :require_admin!, only: [ :archive, :destroy ]
  before_action :require_admin_for_assignment!, only: [ :create, :update ]

  def new
    @ticket = @board.tickets.new(column: default_column)
    load_ticket_form_context(@board.project_id)
    render :new, layout: false if turbo_frame_request?
  end

  def create
    @ticket = @board.tickets.new(ticket_params)
    @ticket.column ||= default_column
    if @ticket.save
      load_board_context(@board)
      respond_to do |format|
        format.turbo_stream { render "boards/update" }
        format.html { redirect_to board_path(@board), notice: "Ticket created." }
      end
    else
      load_ticket_form_context(@board.project_id)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_ticket_form_context(@ticket.project_id)
    render :edit, layout: false if turbo_frame_request?
  end

  def update
    if @ticket.update(ticket_params)
      load_board_context(@ticket.board)
      respond_to do |format|
        format.turbo_stream { render "boards/update" }
        format.html { redirect_to board_path(@ticket.board), notice: "Ticket updated." }
      end
    else
      load_ticket_form_context(@ticket.project_id)
      render :edit, status: :unprocessable_entity
    end
  end

  def comment
    @ticket.ticket_comments.create!(ticket_comment_attrs)
    redirect_to edit_ticket_path(@ticket), notice: "Comment added."
  rescue ActiveRecord::RecordInvalid => e
    @ticket_comment = e.record
    load_ticket_form_context(@ticket.project_id)
    render :edit, status: :unprocessable_entity, layout: false
  end

  def move
    source_column = @ticket.column
    target_column = @ticket.board.columns.find(params[:column_id])
    @ticket.transition_to_column!(target_column)
    load_board_context(@ticket.board)
    @columns_to_refresh = [ source_column, target_column ].uniq
    render_column_update("Ticket moved.")
  end

  def archive
    source_column = @ticket.column
    @ticket.archive!
    load_board_context(@ticket.board)
    @columns_to_refresh = [ source_column ]
    render_column_update("Ticket archived.")
  end

  def destroy
    board = @ticket.board
    source_column = @ticket.column
    @ticket.destroy!
    load_board_context(board)
    @columns_to_refresh = [ source_column ]
    render_column_update("Ticket deleted.")
  rescue ActiveRecord::RecordNotDestroyed
    render plain: @ticket.errors.full_messages.to_sentence, status: :unprocessable_entity
  end

  def pick
    ticket = Ticket.pick_next_for(board: @board, assignee: params[:assignee])
    if ticket
      render json: {
        id: ticket.id,
        title: ticket.title,
        priority: ticket.priority,
        assignee: ticket.assignee,
        column_key: ticket.column.key,
        project_id: ticket.project_id
      }
    else
      render json: { id: nil }, status: :ok
    end
  end

  def markdown_preview
    render html: helpers.ticket_markdown(params[:text].to_s), layout: false
  end

  private

  def render_column_update(notice)
    respond_to do |format|
      format.turbo_stream { render "boards/update_columns" }
      format.html { redirect_to board_path(@board), notice: notice }
    end
  end

  def set_ticket
    @ticket = Ticket.find(params[:id])
    Ticket.reconcile!(@ticket.project)
    @ticket.reload
  end

  def set_board
    @board = Board.find(params[:board_id])
    Ticket.reconcile!(@board.project)
  end

  def load_board_context(board)
    @board = board
    @columns = @board.columns.order(:position)
    @tickets_by_column = @board.tickets.visible_on_board.ordered_for_board.includes(:labels).group_by(&:column_id)
  end

  def load_ticket_form_context(project_id)
    @available_use_cases = UseCase.where(project_id: project_id).order(:name, :id)
  end

  def ticket_params
    permitted = params.require(:ticket).permit(
      :title,
      :description,
      :revision,
      :priority,
      :assignee,
      :column_id,
      :use_case_id,
      :kind,
      :severity,
      :scope,
      :source,
      :resolution,
      :owner,
      :branch,
      :pr,
      :commits
    )
    permitted[:commits] = commits_from(permitted[:commits]) if permitted.key?(:commits)
    permitted
  end

  def ticket_comment_attrs
    {
      body: params.require(:ticket_comment).fetch(:body).to_s,
      author_type: "user",
      author_id: current_user.id,
      author_label: current_user.email_address,
      author_handle: current_user.email_address.to_s.split("@").first
    }
  end

  def commits_from(value)
    value.to_s.lines.map(&:strip).reject(&:blank?)
  end

  def default_column
    @board.columns.order(:position).first
  end

  def require_admin_for_assignment!
    assignee_value = params.dig(:ticket, :assignee)
    return if assignee_value.nil? || assignee_value.to_s.strip.empty?
    return if current_user&.admin?

    respond_to do |format|
      format.turbo_stream { head :forbidden }
      format.json { render json: { error: "forbidden" }, status: :forbidden }
      format.html { redirect_to root_path, alert: "Only admin can assign tickets." }
    end
  end
end
