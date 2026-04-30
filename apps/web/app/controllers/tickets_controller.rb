class TicketsController < ApplicationController
  before_action :set_ticket, only: [ :edit, :update, :move, :archive, :destroy ]
  before_action :set_board, only: [ :new, :create, :pick ]
  before_action :require_admin!, only: [ :archive, :destroy ]
  before_action :require_admin_for_assignment!, only: [ :create, :update ]

  def new
    @ticket = @board.tickets.new(column: default_column)
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
      render :new, status: :unprocessable_entity
    end
  end

  def edit
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
      render :edit, status: :unprocessable_entity
    end
  end

  def move
    source_column = @ticket.column
    target_column = @ticket.board.columns.find(params[:column_id])
    @ticket.transition_to_column!(target_column)
    load_board_context(@ticket.board)
    @columns_to_refresh = [ source_column, target_column ].uniq
    render "boards/update_columns"
  end

  def archive
    source_column = @ticket.column
    @ticket.archive!
    load_board_context(@ticket.board)
    @columns_to_refresh = [ source_column ]
    render "boards/update_columns"
  end

  def destroy
    board = @ticket.board
    source_column = @ticket.column
    @ticket.destroy!
    load_board_context(board)
    @columns_to_refresh = [ source_column ]
    render "boards/update_columns"
  end

  def pick
    ticket = Ticket.pick_next_for(board: @board, assignee: params[:assignee])
    if ticket
      render json: {
        id: ticket.id,
        title: ticket.title,
        priority: ticket.priority,
        assignee: ticket.assignee,
        column_key: ticket.column.key
      }
    else
      render json: { id: nil }, status: :ok
    end
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:id])
  end

  def set_board
    @board = Board.find(params[:board_id])
  end

  def load_board_context(board)
    @board = board
    @columns = @board.columns.order(:position)
    @tickets_by_column = @board.tickets.visible_on_board.ordered_for_board.includes(:labels).group_by(&:column_id)
  end

  def ticket_params
    params.require(:ticket).permit(:title, :description, :priority, :assignee, :column_id)
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
