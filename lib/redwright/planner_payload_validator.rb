# frozen_string_literal: true

require "json"
require_relative "planner_contract"

module Redwright
  class PlannerPayloadValidator
    ValidationResult = Struct.new(
      :valid,
      :intent,
      :message,
      :actions,
      :gaps,
      :control_intent,
      :control_scope,
      :skill_requested,
      :skill_mode,
      :skill_actions,
      :skill_exit_condition,
      :errors,
      keyword_init: true
    )
    REQUIRED_TOP_LEVEL_KEYS = %w[intent message actions].freeze

    def validate(raw_output)
      parsed = JSON.parse(raw_output.to_s)
      return invalid(["payload_not_object"]) unless parsed.is_a?(Hash)

      errors = []
      validate_top_level(parsed, errors)
      validate_actions(parsed["actions"], errors)
      validate_gaps(parsed["gaps"], errors)
      validate_skill_actions(parsed["skill_actions"], errors)

      return invalid(errors) unless errors.empty?

      ValidationResult.new(
        valid: true,
        intent: parsed["intent"].to_s.strip,
        message: parsed["message"].to_s.strip,
        actions: parsed["actions"],
        gaps: parsed["gaps"] || [],
        control_intent: normalized_control_intent(parsed["control_intent"]),
        control_scope: normalized_control_scope(parsed["control_scope"]),
        skill_requested: normalized_skill_requested(parsed["skill_requested"]),
        skill_mode: normalized_skill_mode(parsed["skill_mode"]),
        skill_actions: parsed["skill_actions"] || [],
        skill_exit_condition: normalized_skill_exit_condition(parsed["skill_exit_condition"]),
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

      control_intent = parsed["control_intent"]
      if !control_intent.nil? && !PlannerContract::CONTROL_INTENTS.include?(control_intent.to_s.strip)
        errors << "control_intent_not_allowed"
      end

      control_scope = parsed["control_scope"]
      if !control_scope.nil? && !PlannerContract::CONTROL_SCOPES.include?(control_scope.to_s.strip)
        errors << "control_scope_not_allowed"
      end

      skill_mode = parsed["skill_mode"]
      if !skill_mode.nil? && !PlannerContract::SKILL_MODES.include?(skill_mode.to_s.strip)
        errors << "skill_mode_not_allowed"
      end

      skill_requested = parsed["skill_requested"]
      errors << "skill_requested_not_string" unless skill_requested.nil? || skill_requested.is_a?(String)

      skill_exit_condition = parsed["skill_exit_condition"]
      errors << "skill_exit_condition_not_string" unless skill_exit_condition.nil? || skill_exit_condition.is_a?(String)

      skill_actions = parsed["skill_actions"]
      errors << "skill_actions_not_array" unless skill_actions.nil? || skill_actions.is_a?(Array)

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

    def validate_skill_actions(skill_actions, errors)
      return if skill_actions.nil?
      return unless skill_actions.is_a?(Array)

      skill_actions.each_with_index do |action, idx|
        next unless action.is_a?(Hash)

        extra = action.keys - PlannerContract::ACTION_KEYS
        missing = PlannerContract::ACTION_KEYS - action.keys
        errors << "skill_action_#{idx}_extra_keys:#{extra.sort.join(',')}" unless extra.empty?
        errors << "skill_action_#{idx}_missing_keys:#{missing.sort.join(',')}" unless missing.empty?

        errors << "skill_action_#{idx}_id_invalid" if action["id"].to_s.strip.empty?
        action_type = action["type"].to_s.strip
        errors << "skill_action_#{idx}_type_invalid" if action_type.empty?
        errors << "skill_action_#{idx}_args_not_object" unless action["args"].is_a?(Hash)
        errors << "skill_action_#{idx}_requires_confirmation_not_boolean" unless [true, false].include?(action["requires_confirmation"])
        errors << "skill_action_#{idx}_timeout_ms_invalid" unless positive_integer?(action["timeout_ms"])
        unless PlannerContract::ACTION_ON_FAILURE.include?(action["on_failure"])
          errors << "skill_action_#{idx}_on_failure_not_allowed"
        end
      end
    end

    def positive_integer?(value)
      value.is_a?(Integer) && value.positive?
    end

    def invalid(errors)
      ValidationResult.new(
        valid: false,
        intent: nil,
        message: nil,
        actions: nil,
        gaps: nil,
        control_intent: nil,
        control_scope: nil,
        skill_requested: nil,
        skill_mode: nil,
        skill_actions: nil,
        skill_exit_condition: nil,
        errors: errors
      )
    end

    def normalized_control_intent(raw)
      value = raw.to_s.strip
      return "none" if value.empty?

      value
    end

    def normalized_control_scope(raw)
      value = raw.to_s.strip
      return "none" if value.empty?

      value
    end

    def normalized_skill_requested(raw)
      raw.to_s
    end

    def normalized_skill_mode(raw)
      value = raw.to_s.strip
      return "none" if value.empty?

      value
    end

    def normalized_skill_exit_condition(raw)
      raw.to_s
    end
  end
end
