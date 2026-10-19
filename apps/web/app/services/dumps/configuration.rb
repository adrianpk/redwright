module Dumps
  class Configuration
    DEFAULTS = {"max_context_dumps" => 8, "max_context_dump_bytes" => 20_000}.freeze

    def self.current
      new(Rails.application.config_for(:redwright_dump))
    end

    def initialize(values = {})
      @values = DEFAULTS.merge(values.to_h.stringify_keys)
    end

    def max_context_dumps
      positive_integer("max_context_dumps")
    end

    def max_context_dump_bytes
      positive_integer("max_context_dump_bytes")
    end

    private

    def positive_integer(key)
      value = @values.fetch(key).to_i
      value.positive? ? value : DEFAULTS.fetch(key)
    end
  end
end
