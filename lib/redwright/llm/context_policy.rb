# frozen_string_literal: true

module Redwright
  module LLM
    module ContextPolicy
      WORK_FAMILIES = %w[
        exploration
        implementation
        modification
        diagnosis
        evaluation
        operation
        planning
        documentation
      ].freeze

      CONFIDENCE_BANDS = %w[high medium low].freeze

      FULL_CONTEXT_FALLBACK = "full_context_fallback"

      DEFAULT_POLICY_BY_FAMILY = WORK_FAMILIES.to_h do |family|
        [family, "#{family}_default"]
      end.freeze

      module_function

      def valid_work_family?(value)
        WORK_FAMILIES.include?(value.to_s)
      end

      def valid_confidence?(value)
        CONFIDENCE_BANDS.include?(value.to_s)
      end

      def default_policy_for(family)
        DEFAULT_POLICY_BY_FAMILY[family.to_s]
      end

      def policy_for(family:, confidence:)
        return FULL_CONTEXT_FALLBACK if confidence.to_s == "low"

        default_policy_for(family)
      end
    end
  end
end
