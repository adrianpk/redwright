class TicketsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_ticket, only: [ :move ]

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

  private

  def set_ticket
    @ticket = Ticket.find(params[:id])
  end
end
