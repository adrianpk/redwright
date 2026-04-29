# frozen_string_literal: true

module Redwright
  class SkillSubloopExecutor
    Result = Struct.new(
      :status,
      :attempts,
      :terminal_reason,
      :executed_actions,
      :last_error,
      keyword_init: true
    )

    def initialize(max_attempts: 6, max_seconds: 45, monotonic_clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
      @max_attempts = max_attempts
      @max_seconds = max_seconds
      @monotonic_clock = monotonic_clock
    end

    def run(actions:, cancel_requested: -> { false }, &runner)
      started_at = @monotonic_clock.call
      attempts = 0
      executed = 0
      last_error = nil

      actions.to_a.each do |action|
        return result("canceled", attempts, executed, last_error) if cancel_requested.call
        return result("timeout", attempts, executed, last_error) if timed_out?(started_at)
        return result("max_attempts", attempts, executed, last_error) if attempts >= @max_attempts

        attempts += 1
        outcome = runner.call(action)
        status = outcome.is_a?(Hash) ? outcome.fetch(:status, "ok").to_s : "ok"
        if status != "ok"
          last_error = outcome.is_a?(Hash) ? outcome[:error].to_s : "skill_action_failed"
          return result("failed", attempts, executed, last_error)
        end

        executed += 1
      end

      result("success", attempts, executed, last_error)
    end

    private

    def timed_out?(started_at)
      (@monotonic_clock.call - started_at) >= @max_seconds
    end

    def result(reason, attempts, executed, error)
      Result.new(
        status: reason == "success" ? "ok" : "error",
        attempts: attempts,
        terminal_reason: reason,
        executed_actions: executed,
        last_error: error.to_s
      )
    end
  end
end
