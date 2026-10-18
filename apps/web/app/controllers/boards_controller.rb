class BoardsController < ApplicationController
  before_action :set_board, only: [ :show ]

  def index
    @boards = Board.order(:name)
    if current_project&.boards_scope&.first
      redirect_to board_path(current_project.boards_scope.first)
      nil
    end
  end

  def show
    Ticket.reconcile!(@board.project)
    persist_current_project!(@board.project)
    @columns = @board.columns.order(:position)
    @tickets_by_column = @board.tickets.visible_on_board.ordered_for_board.includes(:labels).group_by(&:column_id)
  end

  private

  def set_board
    @board = Board.find(params[:id])
  end
end
