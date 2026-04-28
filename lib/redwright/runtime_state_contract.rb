# frozen_string_literal: true

module Redwright
  module RuntimeStateContract
    module_function

    TERMINAL_REASONS = %w[
      success
      continue
      ready
      max_turns
      executing
      single_pass
      quality_failed
      max_attempts
      timeout
      planner_rejected_after_retry
      control_pause
      control_stop
      control_resume
    ].freeze

    TRANSITIONS = {
      "collecting_context" => %w[collecting_context waiting_user ready blocked suspended],
      "waiting_user" => %w[collecting_context waiting_user ready blocked suspended],
      "ready" => %w[ready executing blocked suspended],
      "executing" => %w[executing ready blocked suspended],
      "blocked" => %w[suspended],
      "suspended" => %w[suspended collecting_context waiting_user ready blocked]
    }.freeze

    def valid_terminal_reason?(reason)
      TERMINAL_REASONS.include?(reason.to_s)
    end

    def allowed_transition?(from:, to:)
      allowed = TRANSITIONS[from.to_s] || []
      allowed.include?(to.to_s)
    end

    def assert_transition!(from:, to:)
      return true if allowed_transition?(from: from, to: to)

      raise ArgumentError, "invalid_runtime_transition from=#{from} to=#{to}"
    end
  end
end
