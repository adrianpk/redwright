class BoardsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_board, only: [ :show ]

  def index
    @boards = Board.order(:name)
  end

  def show
    @columns = @board.columns.includes(:tickets)
    @tickets_by_column = @board.tickets.ordered_for_board.includes(:labels).group_by(&:column_id)
  end

  private

  def set_board
    @board = Board.find(params[:id])
  end
end
