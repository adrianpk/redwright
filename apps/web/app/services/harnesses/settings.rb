module Harnesses
  class Settings
    FIELDS = %w[authoring_profile ticket_proposal_profile expected_revision request_id].freeze

    def initialize(project:, registry: ProfileRegistry.new)
      @project, @registry = project, registry
      @selection = Selection.new(project: project, registry: registry)
    end

    def snapshot
      profiles_error = nil
      profiles = begin
        @registry.catalog
      rescue Harnesses::Error => error
        profiles_error = error.message
        []
      end
      {"selection" => @selection.current, "profiles" => profiles, "profiles_error" => profiles_error,
        "active_bindings" => @project.harness_operations.where(state: %w[prepared running uncertain]).order(id: :desc).limit(20).map(&:public_state)}
    end

    def change!(actor:, attributes:)
      unless attributes.is_a?(Hash) && (attributes.keys - FIELDS).empty? &&
          attributes["expected_revision"].to_s.match?(/\A(?:0|[1-9][0-9]{0,17})\z/)
        raise Error.new("Supply a profile choice, selection revision and request identity.", code: :invalid_request)
      end
      changes = attributes.slice("authoring_profile", "ticket_proposal_profile").transform_values { |value| value == "" ? nil : value }
      @selection.change!(actor: actor, request_id: attributes["request_id"],
        expected_revision: Integer(attributes.fetch("expected_revision").to_s, 10), changes: changes)
    end
  end
end
