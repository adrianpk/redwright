# frozen_string_literal: true

module Redwright
  class SkillDispatcher
    def before_plan(text:, context:)
      text
    end

    def after_plan(decision:, context:)
      decision
    end

    def before_action(action:, context:)
      action
    end

    def after_action(action:, result:, context:)
      result
    end
  end
end
