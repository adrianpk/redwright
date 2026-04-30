require "test_helper"

class ColumnsControllerTest < ActionDispatch::IntegrationTest
  test "reorder updates board column positions" do
    board = Board.create!(name: "Factory", project_key: "factory-cols")
    c1 = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    c2 = board.columns.create!(key: "review", title: "Review", position: 1)
    c3 = board.columns.create!(key: "merged", title: "Merged", position: 2)

    patch reorder_board_columns_path(board, format: :turbo_stream),
      params: { ordered_ids: [ c3.id, c1.id, c2.id ] },
      as: :json

    assert_response :success
    assert_equal [ c3.id, c1.id, c2.id ], board.columns.order(:position).pluck(:id)
  end
end
