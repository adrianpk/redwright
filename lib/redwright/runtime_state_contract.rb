# frozen_string_literal: true

module Redwright
  module RuntimeStateContract
    module_function

    TURN_PHASES = %w[
      ingest
      resolve_context
      parse_controls
      build_context_packet
      plan
      validate_actions
      execute_actions
      validate_outcome
      persist
      decide_next
      done
      failed
    ].freeze

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

    TURN_PHASE_TRANSITIONS = {
      "ingest" => %w[resolve_context failed],
      "resolve_context" => %w[parse_controls failed],
      "parse_controls" => %w[build_context_packet done failed],
      "build_context_packet" => %w[plan failed],
      "plan" => %w[validate_actions done failed],
      "validate_actions" => %w[execute_actions failed],
      "execute_actions" => %w[validate_outcome failed],
      "validate_outcome" => %w[persist failed],
      "persist" => %w[decide_next failed],
      "decide_next" => %w[build_context_packet done failed],
      "done" => %w[],
      "failed" => %w[]
    }.freeze

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

    def valid_turn_phase?(phase)
      TURN_PHASES.include?(phase.to_s)
    end

    def allowed_turn_phase_transition?(from:, to:)
      allowed = TURN_PHASE_TRANSITIONS[from.to_s] || []
      allowed.include?(to.to_s)
    end

    def assert_turn_phase_transition!(from:, to:)
      return true if allowed_turn_phase_transition?(from: from, to: to)

      raise ArgumentError, "invalid_turn_phase_transition from=#{from} to=#{to}"
    end

    def allowed_transition?(from:, to:)
      allowed = TRANSITIONS[from.to_s] || []
      allowed.include?(to.to_s)
    end

    def assert_transition!(from:, to:)
      return true if allowed_transition?(from: from, to: to)

      raise ArgumentError, "invalid_runtime_transition from=#{from} to=#{to}"
    end

    def transition_id(from:, to:)
      "trs-#{from}-to-#{to}"
    end
  end
end
