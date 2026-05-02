module ProjectSetup
  class StateMachine
    UNCHANGED = Object.new.freeze

    TRANSITIONS = {
      "collecting_context" => %w[awaiting_repository awaiting_repository_confirmation awaiting_alignment_opt_in ready_to_create cancelled],
      "awaiting_repository" => %w[awaiting_repository_confirmation cancelled],
      "awaiting_repository_confirmation" => %w[awaiting_alignment_opt_in ready_to_create cancelled],
      "awaiting_alignment_opt_in" => %w[collecting_alignment ready_to_create cancelled],
      "collecting_alignment" => %w[collecting_alignment ready_to_create cancelled],
      "ready_to_create" => %w[creating_project cancelled],
      "creating_project" => %w[collecting_alignment completed failed needs_reconciliation],
      "completed" => [],
      "cancelled" => [],
      "failed" => [],
      "needs_reconciliation" => []
    }.freeze

    STATUS_BY_STATE = {
      "completed" => "completed",
      "cancelled" => "cancelled",
      "failed" => "failed",
      "needs_reconciliation" => "needs_reconciliation"
    }.freeze

    DEFAULT_TERMINAL_REASON_BY_STATE = {
      "completed" => "completed_without_alignment",
      "cancelled" => "cancelled_by_user",
      "failed" => "failed_reconciled",
      "needs_reconciliation" => "failed_needs_reconciliation"
    }.freeze

    Result = Struct.new(
      :ok,
      :session,
      :from_state,
      :to_state,
      :error_code,
      :error_message,
      keyword_init: true
    ) do
      def ok?
        ok == true
      end
    end

    InvalidTransition = Class.new(StandardError)

    def self.allowed_transition?(from:, to:)
      allowed = TRANSITIONS.fetch(from.to_s, [])
      allowed.include?(to.to_s)
    end

    def initialize(session:)
      @session = session
    end

    def transition_to(to_state, terminal_reason: nil, pending_question: UNCHANGED)
      from_state = @session.current_state.to_s
      target_state = to_state.to_s
      unless ProjectSetupSession::STATES.include?(target_state)
        return failure(from_state: from_state, to_state: target_state, code: "invalid_state", message: "unknown setup state: #{target_state}")
      end

      unless self.class.allowed_transition?(from: from_state, to: target_state)
        return failure(
          from_state: from_state,
          to_state: target_state,
          code: "invalid_transition",
          message: "invalid project setup transition from #{from_state} to #{target_state}"
        )
      end

      attrs = transition_attributes(
        target_state: target_state,
        terminal_reason: terminal_reason,
        pending_question: pending_question
      )
      @session.update!(attrs)
      success(from_state: from_state, to_state: target_state)
    rescue ActiveRecord::RecordInvalid => e
      failure(from_state: from_state, to_state: target_state, code: "invalid_session", message: e.record.errors.full_messages.join(", "))
    end

    def transition_to!(to_state, terminal_reason: nil, pending_question: UNCHANGED)
      result = transition_to(to_state, terminal_reason: terminal_reason, pending_question: pending_question)
      return result.session if result.ok?

      raise InvalidTransition, result.error_message
    end

    def record_turn!(question:, answer:, normalized_fields: {}, source_channel: nil, request_id: nil)
      ProjectSetupTurn.transaction do
        turn = @session.project_setup_turns.create!(
          turn_index: @session.next_turn_index,
          question: question,
          answer: answer,
          normalized_fields: normalized_fields,
          source_channel: source_channel.presence || @session.source_channel,
          request_id: request_id
        )
        @session.update!(turn_counter: @session.turn_counter.to_i + 1)
        turn
      end
    end

    private

    def transition_attributes(target_state:, terminal_reason:, pending_question:)
      attrs = {
        current_state: target_state,
        status: STATUS_BY_STATE.fetch(target_state, "open")
      }
      if ProjectSetupSession::TERMINAL_STATES.include?(target_state)
        attrs[:terminal_reason] = terminal_reason.presence || DEFAULT_TERMINAL_REASON_BY_STATE.fetch(target_state)
        attrs[:pending_question] = nil
      elsif !pending_question.equal?(UNCHANGED)
        attrs[:pending_question] = pending_question
      end
      attrs
    end

    def success(from_state:, to_state:)
      Result.new(
        ok: true,
        session: @session,
        from_state: from_state,
        to_state: to_state,
        error_code: nil,
        error_message: nil
      )
    end

    def failure(from_state:, to_state:, code:, message:)
      Result.new(
        ok: false,
        session: @session,
        from_state: from_state,
        to_state: to_state,
        error_code: code,
        error_message: message
      )
    end
  end
end
