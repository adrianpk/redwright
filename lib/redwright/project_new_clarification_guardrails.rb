# frozen_string_literal: true

module Redwright
  module ProjectNewClarificationGuardrails
    module_function

    def clarification_status_for_loop_state(loop_state)
      case loop_state.to_s
      when "collecting_context", "awaiting_blocking_answers", "awaiting_high_impact_confirmation"
        "open"
      when "ready_to_execute", "executing", "done"
        "closed"
      when "cancelled"
        "cancelled"
      else
        nil
      end
    end

    def evaluate_guardrails(max_question_turns:, turn_counter:, unresolved_blocking_slots:, previous_unresolved_blocking_slots:)
      unresolved = normalize_slots(unresolved_blocking_slots)
      previous = normalize_slots(previous_unresolved_blocking_slots)

      if turn_counter.to_i >= max_question_turns.to_i
        return {
          action: "fallback_required",
          reason: "max_question_turns_reached",
          unresolved_blocking_slots: unresolved
        }
      end

      if stagnating?(unresolved: unresolved, previous: previous)
        return {
          action: "fallback_required",
          reason: "stagnation_detected",
          unresolved_blocking_slots: unresolved
        }
      end

      {
        action: "continue",
        reason: "none",
        unresolved_blocking_slots: unresolved
      }
    end

    def fallback_summary(known_context:, unresolved_blocking_slots:)
      context = normalize_context(known_context)
      unresolved = normalize_slots(unresolved_blocking_slots)
      known = context.sort.map { |k, v| "#{k}=#{v}" }
      {
        known_context: known,
        unresolved_blocking_slots: unresolved,
        required_user_decision: "cancel_or_proceed_with_defaults"
      }
    end

    def merge_resolved_fields(previous:, new_fields:)
      prev = normalize_context(previous)
      add = normalize_context(new_fields)
      prev.merge(add)
    end

    def stagnating?(unresolved:, previous:)
      return false if unresolved.empty? || previous.empty?

      unresolved == previous
    end

    def normalize_slots(slots)
      Array(slots).map(&:to_s).map(&:strip).reject(&:empty?).uniq.sort
    end

    def normalize_context(hash)
      return {} unless hash.is_a?(Hash)

      hash.each_with_object({}) do |(k, v), acc|
        key = k.to_s.strip
        value = v.to_s.strip
        next if key.empty? || value.empty?

        acc[key] = value
      end
    end
  end
end
