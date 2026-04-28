# frozen_string_literal: true

require "json"
require_relative "planner_contract"

module Redwright
  class PlannerPayloadValidator
    ValidationResult = Struct.new(:valid, :intent, :message, :actions, :gaps, :errors, keyword_init: true)
    REQUIRED_TOP_LEVEL_KEYS = %w[intent message actions].freeze

    def validate(raw_output)
      parsed = JSON.parse(raw_output.to_s)
      return invalid(["payload_not_object"]) unless parsed.is_a?(Hash)

      errors = []
      validate_top_level(parsed, errors)
      validate_actions(parsed["actions"], errors)
      validate_gaps(parsed["gaps"], errors)

      return invalid(errors) unless errors.empty?

      ValidationResult.new(
        valid: true,
        intent: parsed["intent"].to_s.strip,
        message: parsed["message"].to_s.strip,
        actions: parsed["actions"],
        gaps: parsed["gaps"] || [],
        errors: []
      )
    rescue JSON::ParserError => e
      invalid(["invalid_json:#{e.message}"])
    end

    private

    def validate_top_level(parsed, errors)
      extra = parsed.keys - PlannerContract::TOP_LEVEL_KEYS
      missing = REQUIRED_TOP_LEVEL_KEYS - parsed.keys
      errors << "top_level_extra_keys:#{extra.sort.join(',')}" unless extra.empty?
      errors << "top_level_missing_keys:#{missing.sort.join(',')}" unless missing.empty?

      intent = parsed["intent"].to_s.strip
      errors << "intent_not_allowed" unless PlannerContract::INTENTS.include?(intent)

      message = parsed["message"]
      errors << "message_not_string" unless message.is_a?(String)
      errors << "message_empty" if message.to_s.strip.empty?

      actions = parsed["actions"]
      errors << "actions_not_array" unless actions.is_a?(Array)

      gaps = parsed["gaps"]
      return if gaps.nil?

      errors << "gaps_not_array" unless gaps.is_a?(Array)
    end

    def validate_actions(actions, errors)
      return unless actions.is_a?(Array)

      actions.each_with_index do |action, idx|
        unless action.is_a?(Hash)
          errors << "action_#{idx}_not_object"
          next
        end

        extra = action.keys - PlannerContract::ACTION_KEYS
        missing = PlannerContract::ACTION_KEYS - action.keys
        errors << "action_#{idx}_extra_keys:#{extra.sort.join(',')}" unless extra.empty?
        errors << "action_#{idx}_missing_keys:#{missing.sort.join(',')}" unless missing.empty?

        errors << "action_#{idx}_id_invalid" if action["id"].to_s.strip.empty?
        action_type = action["type"].to_s.strip
        errors << "action_#{idx}_type_invalid" if action_type.empty?
        unless action_type.empty? || PlannerContract::ACTION_TYPES.include?(action_type)
          errors << "action_#{idx}_type_not_allowed:#{action_type}"
        end
        errors << "action_#{idx}_args_not_object" unless action["args"].is_a?(Hash)
        errors << "action_#{idx}_requires_confirmation_not_boolean" unless [true, false].include?(action["requires_confirmation"])
        errors << "action_#{idx}_timeout_ms_invalid" unless positive_integer?(action["timeout_ms"])
        unless PlannerContract::ACTION_ON_FAILURE.include?(action["on_failure"])
          errors << "action_#{idx}_on_failure_not_allowed"
        end
      end
    end

    def validate_gaps(gaps, errors)
      return if gaps.nil?
      return unless gaps.is_a?(Array)

      gaps.each_with_index do |gap, idx|
        unless gap.is_a?(Hash)
          errors << "gap_#{idx}_not_object"
          next
        end
        extra = gap.keys - PlannerContract::GAP_KEYS
        missing = PlannerContract::GAP_KEYS - gap.keys
        errors << "gap_#{idx}_extra_keys:#{extra.sort.join(',')}" unless extra.empty?
        errors << "gap_#{idx}_missing_keys:#{missing.sort.join(',')}" unless missing.empty?
        errors << "gap_#{idx}_id_invalid" if gap["id"].to_s.strip.empty?
        errors << "gap_#{idx}_question_invalid" if gap["question"].to_s.strip.empty?
        errors << "gap_#{idx}_field_invalid" if gap["field"].to_s.strip.empty?
        errors << "gap_#{idx}_inferred_value_not_string" unless gap["inferred_value"].is_a?(String)
        errors << "gap_#{idx}_resolved_not_boolean" unless [true, false].include?(gap["resolved"])
        errors << "gap_#{idx}_priority_invalid" unless positive_integer?(gap["priority"]) && gap["priority"] <= 5
      end
    end

    def positive_integer?(value)
      value.is_a?(Integer) && value.positive?
    end

    def invalid(errors)
      ValidationResult.new(valid: false, intent: nil, message: nil, actions: nil, gaps: nil, errors: errors)
    end
  end
end
