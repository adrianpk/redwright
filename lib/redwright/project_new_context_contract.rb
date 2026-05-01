# frozen_string_literal: true

module Redwright
  module ProjectNewContextContract
    module_function

    SLOT_ORDER = %w[
      project_name
      description
      stack
      framework
      architecture_style
      test_strategy
      packaging_module_convention
      constraints
    ].freeze

    SLOT_CLASSIFICATIONS = {
      "project_name" => :blocking,
      "description" => :blocking,
      "stack" => :blocking,
      "framework" => :high_impact_confirmation,
      "architecture_style" => :high_impact_confirmation,
      "test_strategy" => :optional,
      "packaging_module_convention" => :optional,
      "constraints" => :optional
    }.freeze

    def slot_names
      SLOT_ORDER.dup
    end

    def slot_classification(slot)
      SLOT_CLASSIFICATIONS[slot.to_s]
    end

    def merge_context(user_inputs:, inferred_inputs:, defaults_authorized_inputs: {})
      merged = {}
      SLOT_ORDER.each do |slot|
        merged[slot] = first_non_empty(
          user_inputs && user_inputs[slot],
          inferred_inputs && inferred_inputs[slot],
          defaults_authorized_inputs && defaults_authorized_inputs[slot]
        )
      end
      merged
    end

    def unresolved_blocking_slots(context)
      SLOT_ORDER.select do |slot|
        SLOT_CLASSIFICATIONS.fetch(slot) == :blocking && blank?(context && context[slot])
      end
    end

    def unresolved_slots(context, classifications: nil)
      allowed = Array(classifications).map(&:to_sym)
      SLOT_ORDER.select do |slot|
        next false unless allowed.empty? || allowed.include?(SLOT_CLASSIFICATIONS.fetch(slot))

        blank?(context && context[slot])
      end
    end

    def sufficiency(context:, proceed_with_defaults_confirmed:)
      unresolved = unresolved_blocking_slots(context)
      ready = unresolved.empty? || proceed_with_defaults_confirmed == true
      {
        ready_to_execute: ready,
        unresolved_blocking_slots: unresolved
      }
    end

    def should_reask_slot?(slot:, resolved_fields:)
      resolved = normalized_resolved_fields(resolved_fields)
      blank?(resolved[slot.to_s])
    end

    def assert_known_slot!(slot)
      return true if SLOT_CLASSIFICATIONS.key?(slot.to_s)

      raise ArgumentError, "unknown_project_new_slot: #{slot}"
    end

    def normalized_resolved_fields(resolved_fields)
      return {} unless resolved_fields.is_a?(Hash)

      resolved_fields.each_with_object({}) { |(k, v), acc| acc[k.to_s] = v }
    end

    def first_non_empty(*values)
      values.each do |value|
        return value if present?(value)
      end
      nil
    end

    def present?(value)
      !blank?(value)
    end

    def blank?(value)
      value.nil? || value.to_s.strip.empty?
    end
  end
end
