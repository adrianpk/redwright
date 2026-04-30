class BoardsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_board, only: [ :show ]

  def index
    @boards = Board.order(:name)
  end

  def show
    @columns = @board.columns.order(:position)
    @tickets_by_column = @board.tickets.visible_on_board.ordered_for_board.includes(:labels).group_by(&:column_id)
  end

  private

  def set_board
    @board = Board.find(params[:id])
  end
end
