require "test_helper"

class BoardsControllerTest < ActionDispatch::IntegrationTest
  test "index renders boards" do
    Board.create!(name: "Factory", project_key: "factory")

    get boards_path
    assert_response :success
    assert_match "Factory", response.body
  end
end

