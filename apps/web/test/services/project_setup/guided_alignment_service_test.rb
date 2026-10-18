require "test_helper"

module ProjectSetup
  class GuidedAlignmentServiceTest < ActiveSupport::TestCase
    test "advances one guided question per turn and completes with persisted artifacts" do
      session = alignment_session

      first = advance(session, "Optimize for a reliable operator loop.", request_id: "req-align-1")
      assert first.ok?, first.errors.inspect
      assert_equal "Guided alignment advanced.", first.summary
      assert_equal "collecting_alignment", session.reload.current_state
      assert_equal question_at(1), session.pending_question
      assert_equal "guided_alignment_question", session.metadata.dig("next_prompt_intent", "kind")
      assert_equal "operators", session.metadata.dig("next_prompt_intent", "question_key")
      assert_equal question_at(1), session.metadata.dig("next_prompt_intent", "metadata", "question_text")
      assert_equal 1, session.turn_counter
      assert_equal 0, session.project.project_attributes.count
      assert_equal 0, session.project.documents.count

      second = advance(session, "Internal operators and reviewer agents.", request_id: "req-align-2")
      assert second.ok?, second.errors.inspect
      assert_equal question_at(2), session.reload.pending_question
      assert_equal 2, session.turn_counter

      third = advance(session, "Keep changes small and preserve manual review gates.", request_id: "req-align-3")
      assert third.ok?, third.errors.inspect

      session.reload
      assert_equal "completed", session.current_state
      assert_equal "completed", session.status
      assert_equal "completed_with_alignment", session.terminal_reason
      assert_nil session.pending_question
      assert_nil session.metadata["next_prompt_intent"]
      assert_equal false, session.metadata["guided_alignment_pending"]
      assert_equal "completed", session.metadata.dig("guided_alignment", "status")
      assert_equal 3, session.project_setup_turns.count

      keys = session.project.project_attributes.order(:key).pluck(:key)
      assert_equal [
        "guided_alignment.constraints",
        "guided_alignment.operators",
        "guided_alignment.primary_outcome"
      ], keys
      document = session.project.documents.find_by!(title: "Guided Alignment Summary", artifact_type: "internal", status: "active")
      assert_equal "active", document.source[:metadata]["status"]
      assert_includes document.body, "Optimize for a reliable operator loop."
      assert_includes document.body, "Keep changes small and preserve manual review gates."
      assert_equal document.id, third.data.fetch("alignment_document_id")
      assert_equal document.id, session.metadata.dig("guided_alignment", "document_id")
      assert_equal "guided_alignment_artifacts_written", third.effects.second.fetch("type")
    end

    test "reuses an existing alignment turn for repeated request id" do
      session = alignment_session
      first = advance(session, "Optimize for deterministic setup.", request_id: "req-reuse")

      repeated = advance(session, "This retry must not create another turn.", request_id: "req-reuse")

      assert first.ok?, first.errors.inspect
      assert repeated.ok?, repeated.errors.inspect
      assert_equal "project_setup_turn_reused", repeated.effects.first.fetch("type")
      assert_equal 1, session.reload.turn_counter
      assert_equal 1, session.project_setup_turns.count
      assert_equal question_at(1), session.pending_question
    end

    test "rejects active alignment without a persisted project" do
      session = ProjectSetupSession.create!(
        actor_identifier: "telegram:missing-project",
        request_id: "req-missing-project",
        source_channel: "telegram",
        current_state: "collecting_alignment",
        pending_question: GuidedAlignmentService.first_question
      )

      result = advance(session, "No project exists.", request_id: "req-no-project")

      assert_not result.ok?
      assert_equal "guided_alignment_project_missing", result.errors.first.fetch(:code)
      assert_equal 0, session.reload.turn_counter
    end

    private

    def alignment_session
      project = create_project(name: "Alignment Project", key: "alignment-#{SecureRandom.hex(4)}")
      ProjectSetupSession.create!(
        actor_identifier: "telegram:42",
        request_id: "req-start",
        source_channel: "telegram",
        current_state: "collecting_alignment",
        pending_question: GuidedAlignmentService.first_question,
        project: project,
        metadata: {
          guided_alignment_pending: true
        }
      )
    end

    def advance(session, answer, request_id:)
      GuidedAlignmentService.new(session: session).advance!(
        answer: answer,
        normalized_fields: {},
        source_channel: "telegram",
        request_id: request_id
      )
    end

    def question_at(index)
      GuidedAlignmentService::QUESTIONS.fetch(index).fetch("question")
    end
  end
end
