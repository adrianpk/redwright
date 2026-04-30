class TicketsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_ticket, only: [ :move ]
  before_action :set_board, only: [ :pick ]

  def move
    target_column = @ticket.board.columns.find(params[:column_id])
    @ticket.transition_to_column!(target_column)

    @board = @ticket.board
    @columns = @board.columns.includes(:tickets)
    @tickets_by_column = @board.tickets.ordered_for_board.includes(:labels).group_by(&:column_id)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to board_path(@board) }
    end
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
end
