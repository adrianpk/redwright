module DumpLoops
  class Configuration
    DEFAULTS = {
      "max_tags" => 5,
      "max_context_dumps" => 8,
      "max_context_dump_bytes" => 20_000,
      "entry_polishing_enabled" => true,
      "curation_enabled" => true
    }.freeze

    def self.current
      new(Rails.application.config_for(:redwright_dump))
    rescue RuntimeError
      new(DEFAULTS)
    end

    def initialize(values = {})
      @values = DEFAULTS.merge(values.to_h.transform_keys(&:to_s))
    end

    def max_tags
      positive_integer("max_tags")
    end

    def max_context_dumps
      positive_integer("max_context_dumps")
    end

    def max_context_dump_bytes
      positive_integer("max_context_dump_bytes")
    end

    def entry_polishing_enabled?
      boolean("entry_polishing_enabled")
    end

    def curation_enabled?
      boolean("curation_enabled")
    end

    private

    attr_reader :values

    def positive_integer(key)
      value = values.fetch(key).to_i
      value.positive? ? value : DEFAULTS.fetch(key)
    end

    def boolean(key)
      value = values.fetch(key)
      return value if value == true || value == false

      DEFAULTS.fetch(key)
    end
  end
end
