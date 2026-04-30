# frozen_string_literal: true

require_relative "trace"

module Redwright
  class ModelResolver
    ResolvedModel = Struct.new(:provider, :name, :alias_id, keyword_init: true)

    def initialize(models_config)
      @models_config = models_config
    end

    def resolve(role)
      role_key = role.to_s
      role_config =
        case role_key
        when "coding"
          @models_config.coding
        when "non_coding"
          @models_config.non_coding
        else
          raise ArgumentError, "unknown model role: #{role_key}"
        end

      candidate = role_config.candidates.first
      raise ArgumentError, "no model candidates configured for role: #{role_key}" unless candidate

      resolved = resolve_alias(candidate)
      Trace.banner("MODEL RESOLUTION", {
        trace_id: Trace.current_trace_id || "none",
        model_role: role_key,
        provider: resolved.provider,
        model: resolved.name,
        model_alias: resolved.alias_id || "",
        candidates_count: role_config.candidates.length
      })

      resolved
    end

    private

    def resolve_alias(candidate)
      alias_map = @models_config.respond_to?(:aliases) ? (@models_config.aliases || {}) : {}
      alias_target = alias_map[candidate.name.to_s]
      unless alias_target
        provider = candidate.provider.to_s.strip
        raise ArgumentError, "missing provider for non-aliased model candidate: #{candidate.name}" if provider.empty?

        return ResolvedModel.new(provider: candidate.provider, name: candidate.name, alias_id: nil)
      end

      ResolvedModel.new(
        provider: alias_target.provider,
        name: alias_target.name,
        alias_id: candidate.name
      )
    end
  end
end
