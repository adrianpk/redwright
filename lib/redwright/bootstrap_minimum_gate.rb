# frozen_string_literal: true

module Redwright
  class BootstrapMinimumGate
    TECHNICAL_BLOCKING_FIELDS = %w[
      project_name
      module_name
      package_name
      namespace
    ].freeze

    MUTATING_ACTION_TYPES = %w[
      run
      write_file
      apply_patch
      git_branch
      git_commit
      git_push
      write_files
      run_command
      run_commands
    ].freeze

    def evaluate(intent:, actions:, gaps:)
      unresolved = unresolved_gaps(gaps)
      return result([], unresolved) unless change_intent?(intent) && mutating_actions?(actions)

      technical = unresolved.select { |gap| technical_field?(gap["field"]) }
      optional = unresolved.reject { |gap| technical_field?(gap["field"]) }
      result(technical, optional)
    end

    private

    def unresolved_gaps(gaps)
      return [] unless gaps.is_a?(Array)

      gaps.select do |gap|
        gap.is_a?(Hash) && gap["resolved"] == false && !gap["question"].to_s.strip.empty?
      end
    end

    def change_intent?(intent)
      intent.to_s.strip == "change"
    end

    def mutating_actions?(actions)
      return false unless actions.is_a?(Array)

      actions.any? do |action|
        action_type = if action.is_a?(Hash)
                        action["type"].to_s
                      else
                        ""
                      end
        MUTATING_ACTION_TYPES.include?(action_type)
      end
    end

    def technical_field?(field)
      TECHNICAL_BLOCKING_FIELDS.include?(field.to_s.strip)
    end

    def result(technical, optional)
      {
        technical_blocking_gaps: technical,
        alignment_optional_gaps: optional
      }
    end
  end
end
