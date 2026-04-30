class ColumnsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_board

  def reorder
    raw_ids = params[:ordered_ids]
    ordered_ids = if raw_ids.is_a?(ActionController::Parameters) || raw_ids.is_a?(Hash)
      raw_ids.to_h.values.map(&:to_i)
    else
      Array(raw_ids).map(&:to_i)
    end
    columns = @board.columns.order(:position).to_a
    return head :unprocessable_entity if ordered_ids.size != columns.size

    id_to_position = ordered_ids.each_with_index.to_h
    Column.transaction do
      columns.each_with_index do |column, idx|
        column.update!(position: 10_000 + idx)
      end
      columns.each do |column|
        next unless id_to_position.key?(column.id)

        column.update!(position: id_to_position[column.id])
      end
    end

    load_board_context
    render "boards/update"
  end

  private

  def set_board
    @board = Board.find(params[:board_id])
  end

  def load_board_context
    @columns = @board.columns.order(:position)
    @tickets_by_column = @board.tickets.visible_on_board.ordered_for_board.includes(:labels).group_by(&:column_id)
  end
end
