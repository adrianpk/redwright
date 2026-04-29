# frozen_string_literal: true

module Redwright
  class SkillRouter
    Activation = Struct.new(
      :name,
      :mode,
      :confidence,
      :reason,
      keyword_init: true
    )

    def resolve(explicit_skill_name:, decision:)
      explicit = explicit_skill_name.to_s.strip
      unless explicit.empty?
        return Activation.new(
          name: explicit,
          mode: "explicit",
          confidence: 1.0,
          reason: "explicit_slash_skill"
        )
      end

      return nil unless decision

      requested = value_from_decision(decision, :skill_requested)
      mode = value_from_decision(decision, :skill_mode)
      return nil if requested.empty?
      return nil unless %w[explicit inferred].include?(mode)

      Activation.new(
        name: requested,
        mode: mode,
        confidence: mode == "explicit" ? 0.95 : 0.8,
        reason: "planner_skill_#{mode}"
      )
    end

    private

    def value_from_decision(decision, field)
      return "" unless decision.respond_to?(field)

      decision.public_send(field).to_s.strip
    rescue StandardError
      ""
    end
  end
end
