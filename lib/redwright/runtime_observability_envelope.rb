# frozen_string_literal: true

require "time"

module Redwright
  class RuntimeObservabilityEnvelope
    RUNTIMES = %w[interactive factory].freeze

    def build(runtime:, event:, trace_id:, payload: {})
      runtime_name = runtime.to_s
      validate_runtime!(runtime_name)

      {
        "runtime" => runtime_name,
        "event" => event.to_s,
        "trace_id" => trace_id.to_s,
        "timestamp" => Time.now.utc.iso8601,
        "payload" => payload.is_a?(Hash) ? payload : { "raw" => payload.to_s }
      }
    end

    private

    def validate_runtime!(runtime)
      return if RUNTIMES.include?(runtime)

      raise ArgumentError, "unsupported runtime: #{runtime}"
    end
  end
end
