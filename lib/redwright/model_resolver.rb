# frozen_string_literal: true

require_relative "trace"

module Redwright
  class ModelResolver
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

      Trace.banner("MODEL RESOLUTION", {
        trace_id: Trace.current_trace_id || "none",
        model_role: role_key,
        provider: candidate.provider,
        model: candidate.name,
        candidates_count: role_config.candidates.length
      })

      candidate
    end
  end
end
