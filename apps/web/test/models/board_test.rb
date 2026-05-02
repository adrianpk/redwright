require "test_helper"

class BoardTest < ActiveSupport::TestCase
  test "is valid with project association and required fields" do
    board = Board.new(
      name: "Factory",
      project_key: "factory",
      project: create_project(key: "factory")
    )

    assert board.valid?
  end

  test "requires project association" do
    board = Board.new(name: "Factory", project_key: "factory")

    assert_not board.valid?
    assert_includes board.errors[:project], "must exist"
  end
end
