# frozen_string_literal: true

module Redwright
  module AlignmentContract
    module_function

    TERMINAL_STATUSES = %w[continue ready user_stop blocked].freeze
    TRANSITIONS = {
      "collecting_context" => %w[collecting_context waiting_user ready blocked paused],
      "waiting_user" => %w[collecting_context waiting_user ready blocked paused],
      "paused" => %w[collecting_context waiting_user ready blocked paused]
    }.freeze

    def valid_terminal_status?(status)
      TERMINAL_STATUSES.include?(status.to_s)
    end

    def allowed_transition?(from:, to:)
      allowed = TRANSITIONS[from.to_s] || []
      allowed.include?(to.to_s)
    end
  end
end
