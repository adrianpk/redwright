# frozen_string_literal: true

module Redwright
  class TelegramMessageRenderer
    def initialize(execution_summary: TelegramExecutionSummary.new)
      @execution_summary = execution_summary
    end

    def success(result:, trace_id:, quality_summary:, attempts:, terminal_reason:, mode:)
      parts = []
      parts << "Started task #{result.task.id} in project #{result.project.id}."
      parts << "Workstream: #{result.workstream.id} (state: #{result.workstream.state})."
      execution = @execution_summary.build(
        result,
        quality_summary: nil,
        attempts: attempts,
        terminal_reason: terminal_reason,
        mode: mode
      )
      if execution
        parts << "Actions: #{execution[:succeeded_actions]} succeeded, #{execution[:failed_actions]} failed."
      end
      parts << "Mode: #{mode}."
      parts << "Attempts: #{attempts} (terminal: #{terminal_reason})."
      if quality_summary
        parts << "Quality checks: #{quality_summary[:passed_checks]}/#{quality_summary[:total_checks]} passed, #{quality_summary[:failed_checks]} failed."
      end
      confirmation_hint = confirmation_required_hint(result)
      parts << confirmation_hint if confirmation_hint
      parts << "Trace: #{trace_id}"
      parts.join("\n")
    end

    def error(message:, trace_id:)
      "Error: #{message}\nTrace: #{trace_id}"
    end

    def clarify(question:, trace_id:)
      [
        question.to_s,
        "Trace: #{trace_id}"
      ].join("\n")
    end

    def planner_rejection(reason:, trace_id:)
      [
        "Planner output was rejected before execution.",
        "Reason: #{reason}",
        "No actions were executed for this turn.",
        "Trace: #{trace_id}"
      ].join("\n")
    end

    private

    def confirmation_required_hint(result)
      action_results = if result.respond_to?(:action_results)
                         result.action_results || []
                       else
                         []
                       end
      blocked = action_results.select do |r|
        next false unless r.respond_to?(:status) && r.status != "ok"
        next false unless r.respond_to?(:error_message) && r.error_message.to_s == "confirmation_required"

        if r.respond_to?(:action_type)
          %w[git_commit git_push].include?(r.action_type.to_s)
        else
          true
        end
      end
      return nil if blocked.empty?

      ids = blocked.map { |r| r.respond_to?(:action_id) ? r.action_id : "unknown" }.join(", ")
      "Commit/push actions were blocked by confirmation policy (#{ids}). Ask to retry with explicit confirmation."
    end
  end
end
