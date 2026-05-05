require "test_helper"

module QuizLoops
  class ConfigurationTest < ActiveSupport::TestCase
    test "loads defaults from yaml-backed config" do
      config = Configuration.current

      assert_equal 50, config.max_questions
      assert_equal 3, config.max_follow_up_depth
      assert_equal 3, config.max_tags
    end

    test "falls back to defaults for invalid values" do
      config = Configuration.new(
        "max_questions" => 0,
        "max_follow_up_depth" => "",
        "max_tags" => -1
      )

      assert_equal 50, config.max_questions
      assert_equal 3, config.max_follow_up_depth
      assert_equal 3, config.max_tags
    end
  end
end
