require "test_helper"

class ProjectSetupTurnTest < ActiveSupport::TestCase
  test "is valid with required turn data" do
    session = ProjectSetupSession.create!(
      actor_identifier: "human-1",
      request_id: "req-turn-valid",
      source_channel: "telegram"
    )
    turn = session.project_setup_turns.new(
      turn_index: 1,
      question: "Repository?",
      answer: "acme/repo"
    )
    turn.normalized_fields = {repository_input: "acme/repo"}

    assert turn.valid?, turn.errors.full_messages.inspect
    assert_equal "telegram", turn.source_channel
    assert_equal({"repository_input" => "acme/repo"}, turn.normalized_fields)
  end

  test "requires question answer and positive turn index" do
    session = ProjectSetupSession.create!(actor_identifier: "human-1", request_id: "req-turn-required")
    turn = session.project_setup_turns.new(turn_index: 0)

    assert_not turn.valid?
    assert_includes turn.errors[:turn_index], "must be greater than or equal to 1"
    assert_includes turn.errors[:question], "can't be blank"
    assert_includes turn.errors[:answer], "can't be blank"
  end

  test "enforces unique turn index per setup session" do
    session = ProjectSetupSession.create!(actor_identifier: "human-1", request_id: "req-turn-unique")
    session.project_setup_turns.create!(
      turn_index: 1,
      source_channel: "web",
      question: "Repository?",
      answer: "acme/repo"
    )
    duplicate = session.project_setup_turns.new(
      turn_index: 1,
      source_channel: "web",
      question: "Stack?",
      answer: "ruby"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:turn_index], "has already been taken"
  end
end
