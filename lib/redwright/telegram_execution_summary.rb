# frozen_string_literal: true

module Redwright
  class TelegramExecutionSummary
    def build(result, quality_summary: nil, attempts: 1, terminal_reason: "single_pass", mode: nil)
      action_results = if result.respond_to?(:action_results)
                         result.action_results || []
                       else
                         []
                       end
      if action_results.empty? && quality_summary.nil?
        resolved_terminal_reason = if result.respond_to?(:terminal_reason) && result.terminal_reason
                                     result.terminal_reason
                                   else
                                     terminal_reason
                                   end
        return {
          total_actions: 0,
          succeeded_actions: 0,
          failed_actions: 0,
          failed_action_ids: [],
          attempts: attempts,
          terminal_reason: resolved_terminal_reason
        }
      end

      total = action_results.size
      failed = action_results.count { |r| r.status != "ok" }
      succeeded = total - failed
      failed_action_ids = action_results.select { |r| r.status != "ok" }.map(&:action_id)
      summary = {
        total_actions: total,
        succeeded_actions: succeeded,
        failed_actions: failed,
        failed_action_ids: failed_action_ids,
        attempts: attempts,
        terminal_reason: terminal_reason
      }
      summary[:mode] = mode if mode
      summary[:quality] = quality_summary if quality_summary
      summary
    end
  end
end
