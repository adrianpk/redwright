# frozen_string_literal: true

module Redwright
  module LLM
    module ContextPolicy
      Policy = Struct.new(
        :name,
        :work_family,
        :included_layers,
        :fallback,
        keyword_init: true
      ) do
        def fallback?
          fallback == true
        end

        def to_h
          {
            name: name,
            work_family: work_family,
            included_layers: included_layers,
            fallback: fallback?
          }
        end
      end

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

      ALL_CONTEXT_LAYERS = %w[
        agent
        project
        prompt
        concrete_files
        file_tree
        tree_sitter
        llm_based
        docs
        quizzes
        dumps
        conversation
        protocols
      ].freeze

      DEFAULT_INCLUDED_LAYERS_BY_FAMILY = {
        "exploration" => %w[agent project prompt file_tree docs protocols conversation],
        "implementation" => %w[agent project prompt concrete_files file_tree tree_sitter docs protocols conversation],
        "modification" => %w[agent project prompt concrete_files file_tree tree_sitter docs protocols conversation],
        "diagnosis" => %w[agent project prompt concrete_files file_tree tree_sitter llm_based docs protocols conversation],
        "evaluation" => %w[agent project prompt concrete_files file_tree tree_sitter docs protocols conversation],
        "operation" => %w[agent project prompt concrete_files docs protocols conversation],
        "planning" => %w[agent project prompt file_tree llm_based docs quizzes dumps conversation protocols],
        "documentation" => %w[agent project prompt concrete_files file_tree docs quizzes dumps conversation protocols]
      }.freeze

      POLICY_REGISTRY = WORK_FAMILIES.each_with_object({}) do |family, registry|
        policy_name = "#{family}_default"
        registry[policy_name] = Policy.new(
          name: policy_name,
          work_family: family,
          included_layers: DEFAULT_INCLUDED_LAYERS_BY_FAMILY.fetch(family),
          fallback: false
        )
      end.merge(
        FULL_CONTEXT_FALLBACK => Policy.new(
          name: FULL_CONTEXT_FALLBACK,
          work_family: nil,
          included_layers: [],
          fallback: true
        )
      ).freeze

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

      def policy_registry
        POLICY_REGISTRY
      end

      def policy_names
        POLICY_REGISTRY.keys
      end

      def fetch_policy(policy_name)
        POLICY_REGISTRY[policy_name.to_s]
      end

      def policy_for(family:, confidence:)
        return FULL_CONTEXT_FALLBACK if confidence.to_s == "low"

        default_policy_for(family)
      end
    end
  end
end
