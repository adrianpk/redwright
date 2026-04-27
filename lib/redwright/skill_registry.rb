# frozen_string_literal: true

module Redwright
  class SkillRegistry
    def initialize(manifests:)
      @manifests = manifests
      @by_id = manifests.to_h { |m| [m.id, m] }
    end

    def all
      @manifests
    end

    def get(id)
      @by_id[id]
    end

    def resolve_action(action_type)
      @manifests.find { |m| m.actions.include?(action_type) }
    end
  end
end
