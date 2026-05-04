module HeavyInteractionSagas
  class Effect
    VISIBILITIES = %w[public internal debug].freeze

    attr_reader :type, :visibility, :data

    def initialize(type:, visibility: "public", data: {})
      @type = type.to_s
      @visibility = visibility.to_s
      @data = normalize_hash(data)
      validate!
    end

    def to_h
      {
        "type" => type,
        "visibility" => visibility
      }.merge(data)
    end

    private

    def validate!
      raise ArgumentError, "effect type is required" if type.empty?
      raise ArgumentError, "unsupported effect visibility: #{visibility}" unless VISIBILITIES.include?(visibility)
    end

    def normalize_hash(value)
      return {} unless value.is_a?(Hash)

      value.transform_keys(&:to_s)
    end
  end
end
