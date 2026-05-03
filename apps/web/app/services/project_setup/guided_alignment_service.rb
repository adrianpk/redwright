module ProjectSetup
  class GuidedAlignmentService
    QUESTIONS = [
      {
        "key" => "primary_outcome",
        "question" => "What primary outcome should this project optimize for first?"
      },
      {
        "key" => "operators",
        "question" => "Who will use or operate this project?"
      },
      {
        "key" => "constraints",
        "question" => "What constraints, risks, or non-goals should agents preserve?"
      }
    ].freeze
    ATTRIBUTE_SOURCE = "guided_alignment".freeze
    ATTRIBUTE_WEIGHT = 4
    DOCUMENT_TITLE = "Guided Alignment Summary".freeze

    Result = Struct.new(:ok, :session, :turn, :summary, :effects, :errors, :data, keyword_init: true) do
      def ok?
        ok == true
      end
    end

    def self.first_question
      QUESTIONS.first.fetch("question")
    end

    def initialize(session:)
      @session = session
    end

    def replay(request_id:)
      turn = alignment_turn_for_request(request_id)
      return nil unless turn

      success(
        turn: turn,
        summary: summary_for(session),
        effects: [
          {
            "type" => "project_setup_turn_reused",
            "session_id" => session.id,
            "turn_index" => turn.turn_index
          }
        ]
      )
    end

    def advance!(answer:, normalized_fields: {}, source_channel:, request_id:)
      cleaned_answer = answer.to_s.strip
      return failure(code: "invalid_alignment_answer", message: "answer is required") if cleaned_answer.empty?
      return failure(code: "guided_alignment_not_active", message: "guided alignment is not active for this setup session") unless session.current_state == "collecting_alignment"
      return failure(code: "guided_alignment_project_missing", message: "guided alignment requires a persisted project") unless session.project

      result = nil
      ProjectSetupSession.transaction do
        session.lock!

        repeated = alignment_turn_for_request(request_id)
        if repeated
          result = success(
            turn: repeated,
            summary: summary_for(session),
            effects: [
              {
                "type" => "project_setup_turn_reused",
                "session_id" => session.id,
                "turn_index" => repeated.turn_index
              }
            ]
          )
          next
        end

        answers = alignment_answers
        question_index = answers.length
        if question_index >= QUESTIONS.length
          result = failure(
            code: "guided_alignment_turn_limit_exceeded",
            message: "guided alignment already reached its bounded turn limit"
          )
          next
        end

        question = QUESTIONS.fetch(question_index)
        completed = question_index == QUESTIONS.length - 1
        turn = StateMachine.new(session: session).record_turn!(
          question: question.fetch("question"),
          answer: cleaned_answer,
          normalized_fields: turn_fields(
            question: question,
            question_index: question_index,
            completed: completed,
            normalized_fields: normalized_fields
          ),
          source_channel: source_channel,
          request_id: request_id
        )

        next_answers = answers + [
          {
            "key" => question.fetch("key"),
            "question" => question.fetch("question"),
            "answer" => cleaned_answer
          }
        ]
        write_alignment_metadata!(answers: next_answers, completed: completed)

        if completed
          output_data = persist_alignment_outputs!(answers: next_answers)
          StateMachine.new(session: session).transition_to!("completed", terminal_reason: "completed_with_alignment")
          SagaState.new(session: session).mark_completed!(
            project: session.project,
            board: session.project.boards_scope.first,
            document: session.project.documents_scope.first,
            starter_ticket: nil,
            attribute_ids: output_data.fetch("alignment_project_attribute_ids"),
            workspace: {}
          )
          result = success(
            turn: turn,
            summary: "Guided alignment completed.",
            effects: [
              turn_recorded_effect(turn),
              {
                "type" => "guided_alignment_artifacts_written",
                "session_id" => session.id,
                "project_id" => session.project_id,
                "document_id" => output_data.fetch("alignment_document_id"),
                "project_attribute_ids" => output_data.fetch("alignment_project_attribute_ids")
              },
              {
                "type" => "project_setup_completed",
                "session_id" => session.id,
                "terminal_reason" => "completed_with_alignment"
              }
            ],
            data: output_data
          )
        else
          next_question = QUESTIONS.fetch(question_index + 1)
          StateMachine.new(session: session).transition_to!("collecting_alignment", pending_question: next_question.fetch("question"))
          SagaState.new(session: session).mark_questionnaire!
          result = success(
            turn: turn,
            summary: "Guided alignment advanced.",
            effects: [
              turn_recorded_effect(turn),
              {
                "type" => "guided_alignment_question_advanced",
                "session_id" => session.id,
                "next_question_index" => question_index + 2
              }
            ]
          )
        end
      end

      result
    end

    private

    attr_reader :session

    def alignment_turn_for_request(request_id)
      return nil if request_id.to_s.empty?

      turn = session.project_setup_turns.find_by(request_id: request_id.to_s)
      return nil unless turn
      return nil unless turn.normalized_fields["alignment_key"].present?

      turn
    end

    def alignment_answers
      stored = alignment_metadata["answers"]
      return stored if stored.is_a?(Array)

      session.project_setup_turns.order(:turn_index).filter_map do |turn|
        fields = turn.normalized_fields
        next unless fields["alignment_key"].present?

        {
          "key" => fields.fetch("alignment_key"),
          "question" => turn.question,
          "answer" => turn.answer
        }
      end
    end

    def alignment_metadata
      payload = session.metadata["guided_alignment"]
      payload.is_a?(Hash) ? payload : {}
    end

    def write_alignment_metadata!(answers:, completed:)
      metadata = session.metadata
      metadata["guided_alignment"] = {
        "status" => completed ? "completed" : "in_progress",
        "question_count" => QUESTIONS.length,
        "answered_count" => answers.length,
        "answers" => answers
      }
      metadata["guided_alignment_pending"] = !completed
      session.metadata = metadata
      session.save!
    end

    def persist_alignment_outputs!(answers:)
      project = session.project
      attributes = answers.map do |answer|
        attribute = ProjectAttribute.find_or_initialize_by(
          project: project,
          key: "guided_alignment.#{answer.fetch("key")}"
        )
        attribute.value = answer.fetch("answer")
        attribute.weight = ATTRIBUTE_WEIGHT
        attribute.source = ATTRIBUTE_SOURCE
        attribute.save!
        attribute
      end
      document = Document.find_or_initialize_by(
        project: project,
        artifact_type: "draft",
        title: DOCUMENT_TITLE
      )
      document.body = alignment_document_body(answers: answers)
      document.editable = true
      document.save!

      output_data = {
        "alignment_document_id" => document.id,
        "alignment_project_attribute_ids" => attributes.map(&:id),
        "alignment_project_attribute_keys" => attributes.map(&:key)
      }
      metadata = session.metadata
      metadata["guided_alignment"] = alignment_metadata.merge(
        "document_id" => document.id,
        "project_attribute_ids" => attributes.map(&:id),
        "project_attribute_keys" => attributes.map(&:key)
      )
      session.metadata = metadata
      session.save!
      output_data
    end

    def alignment_document_body(answers:)
      sections = answers.map do |answer|
        heading = answer.fetch("key").tr("_", " ").titleize
        "## #{heading}\n\n#{answer.fetch("answer")}"
      end

      [
        "# #{DOCUMENT_TITLE}",
        "",
        "This draft captures the project setup guided alignment answers.",
        "",
        *sections,
        "",
        "## Source",
        "",
        "- setup_session_id: #{session.id}",
        "- source_channel: #{session.source_channel}",
        "- answer_count: #{answers.length}"
      ].join("\n")
    end

    def turn_fields(question:, question_index:, completed:, normalized_fields:)
      stringify_hash(normalized_fields).merge(
        "alignment_key" => question.fetch("key"),
        "alignment_question" => question.fetch("question"),
        "alignment_index" => question_index + 1,
        "alignment_question_count" => QUESTIONS.length,
        "alignment_completed" => completed
      )
    end

    def stringify_hash(value)
      return {} unless value.is_a?(Hash)

      value.to_h.transform_keys(&:to_s)
    end

    def turn_recorded_effect(turn)
      {
        "type" => "project_setup_turn_recorded",
        "session_id" => session.id,
        "turn_index" => turn.turn_index
      }
    end

    def summary_for(session)
      return "Guided alignment completed." if session.current_state == "completed"

      "Guided alignment advanced."
    end

    def success(turn:, summary:, effects:, data: {})
      Result.new(
        ok: true,
        session: session.reload,
        turn: turn,
        summary: summary,
        effects: effects,
        errors: [],
        data: data
      )
    end

    def failure(code:, message:)
      Result.new(
        ok: false,
        session: session.reload,
        turn: nil,
        summary: "Guided alignment could not advance.",
        effects: [],
        errors: [
          {
            code: code,
            message: message,
            details: []
          }
        ],
        data: {}
      )
    end
  end
end
