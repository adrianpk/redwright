# frozen_string_literal: true

module Redwright
  class AlignmentSufficiencyHeuristic
    SIMPLE_HINTS = [
      "simple",
      "tiny",
      "minimal",
      "quick",
      "small"
    ].freeze

    def sufficient?(objective:, answered_turns_count:)
      return false if answered_turns_count.to_i < 1

      text = objective.to_s.downcase.strip
      return true if SIMPLE_HINTS.any? { |hint| text.include?(hint) }

      words = text.split(/\s+/).reject(&:empty?)
      words.size <= 10
    end
  end
end
