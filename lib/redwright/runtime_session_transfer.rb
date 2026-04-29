# frozen_string_literal: true

require "time"

module Redwright
  class RuntimeSessionTransfer
    RUNTIMES = %w[interactive factory].freeze

    Result = Struct.new(:session, :from_runtime, :to_runtime, :transferred_at, keyword_init: true)

    def transfer(session:, from_runtime:, to_runtime:)
      from_name = from_runtime.to_s
      to_name = to_runtime.to_s

      validate_runtime!(from_name)
      validate_runtime!(to_name)
      raise ArgumentError, "session must be hash" unless session.is_a?(Hash)

      copied = session.dup
      copied["runtime"] = to_name
      copied["previous_runtime"] = from_name
      copied["transferred_at"] = Time.now.utc.iso8601

      Result.new(
        session: copied,
        from_runtime: from_name,
        to_runtime: to_name,
        transferred_at: copied["transferred_at"]
      )
    end

    private

    def validate_runtime!(runtime)
      return if RUNTIMES.include?(runtime)

      raise ArgumentError, "unsupported runtime: #{runtime}"
    end
  end
end
