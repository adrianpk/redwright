require "test_helper"

module ProjectSetup
  class StateMachineTest < ActiveSupport::TestCase
    test "transitions through allowed setup states" do
      session = setup_session
      machine = StateMachine.new(session: session)

      result = machine.transition_to("awaiting_repository", pending_question: "Which repository should be attached?")

      assert result.ok?, result.error_message
      assert_equal "collecting_context", result.from_state
      assert_equal "awaiting_repository", result.to_state
      assert_equal "open", session.status
      assert_equal "awaiting_repository", session.current_state
      assert_equal "Which repository should be attached?", session.pending_question
    end

    test "rejects invalid transitions without mutating session" do
      session = setup_session(current_state: "collecting_context")
      machine = StateMachine.new(session: session)

      result = machine.transition_to("completed")

      assert_not result.ok?
      assert_equal "invalid_transition", result.error_code
      assert_equal "collecting_context", session.reload.current_state
      assert_nil session.terminal_reason
    end

    test "terminal transition sets status reason and clears pending question" do
      session = setup_session(current_state: "collecting_alignment", pending_question: "Confirm?", status: "open")
      machine = StateMachine.new(session: session)

      result = machine.transition_to("completed", terminal_reason: "completed_with_alignment")

      assert result.ok?, result.error_message
      assert_equal "completed", session.current_state
      assert_equal "completed", session.status
      assert_equal "completed_with_alignment", session.terminal_reason
      assert_nil session.pending_question
    end

    test "transition bang raises on invalid transition" do
      session = setup_session(current_state: "completed", status: "completed", terminal_reason: "completed_without_alignment")
      machine = StateMachine.new(session: session)

      error = assert_raises(StateMachine::InvalidTransition) do
        machine.transition_to!("awaiting_repository")
      end
      assert_match "invalid project setup transition", error.message
    end

    test "records ordered turns and increments session turn counter atomically" do
      session = setup_session(source_channel: "telegram")
      machine = StateMachine.new(session: session)

      first = machine.record_turn!(
        question: "Repository?",
        answer: "acme/repo",
        normalized_fields: {repository_input: "acme/repo"},
        request_id: "req-turn-1"
      )
      second = machine.record_turn!(
        question: "Use guided alignment?",
        answer: "yes",
        normalized_fields: {guided_alignment: true},
        request_id: "req-turn-2"
      )

      assert_equal 1, first.turn_index
      assert_equal 2, second.turn_index
      assert_equal "telegram", first.source_channel
      assert_equal 2, session.reload.turn_counter
      assert_equal({"guided_alignment" => true}, second.normalized_fields)
    end

    test "does not increment turn counter when turn is invalid" do
      session = setup_session
      machine = StateMachine.new(session: session)

      assert_raises(ActiveRecord::RecordInvalid) do
        machine.record_turn!(question: "Repository?", answer: "")
      end

      assert_equal 0, session.reload.turn_counter
      assert_equal 0, session.project_setup_turns.count
    end

    private

    def setup_session(**attrs)
      defaults = {
        actor_identifier: "human-1",
        request_id: "req-#{SecureRandom.hex(4)}"
      }
      ProjectSetupSession.create!(defaults.merge(attrs))
    end
  end
end
