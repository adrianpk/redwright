# frozen_string_literal: true

module Redwright
  module ProjectNewLoopContract
    module_function

    STATES = %w[
      collecting_context
      awaiting_blocking_answers
      awaiting_high_impact_confirmation
      ready_to_execute
      executing
      done
      cancelled
    ].freeze

    TERMINAL_OUTCOMES = %w[
      cancelled
      confirmed_and_executed
      proceeded_with_defaults
    ].freeze

    TRANSITIONS = {
      "collecting_context" => %w[
        collecting_context
        awaiting_blocking_answers
        awaiting_high_impact_confirmation
        ready_to_execute
        cancelled
      ],
      "awaiting_blocking_answers" => %w[
        awaiting_blocking_answers
        awaiting_high_impact_confirmation
        ready_to_execute
        cancelled
      ],
      "awaiting_high_impact_confirmation" => %w[
        awaiting_high_impact_confirmation
        ready_to_execute
        cancelled
      ],
      "ready_to_execute" => %w[
        executing
        cancelled
      ],
      "executing" => %w[
        done
        cancelled
      ],
      "done" => %w[],
      "cancelled" => %w[]
    }.freeze

    def valid_state?(state)
      STATES.include?(state.to_s)
    end

    def valid_terminal_outcome?(outcome)
      TERMINAL_OUTCOMES.include?(outcome.to_s)
    end

    def allowed_transition?(from:, to:)
      allowed = TRANSITIONS[from.to_s] || []
      allowed.include?(to.to_s)
    end

    def assert_transition!(from:, to:)
      return true if allowed_transition?(from: from, to: to)

      raise ArgumentError, "invalid_project_new_loop_transition from=#{from} to=#{to}"
    end

    def execution_allowed?(blocking_resolved:, proceed_with_defaults_confirmed:)
      blocking_resolved == true || proceed_with_defaults_confirmed == true
    end

    def assert_execution_allowed!(blocking_resolved:, proceed_with_defaults_confirmed:)
      return true if execution_allowed?(
        blocking_resolved: blocking_resolved,
        proceed_with_defaults_confirmed: proceed_with_defaults_confirmed
      )

      raise ArgumentError, "project_new_execution_not_allowed missing_blocking_context"
    end
  end
end
