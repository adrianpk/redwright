module HeavyInteractionSagas
  class StepResult
    STATUSES = %w[ok skipped pending failed needs_reconciliation].freeze

    attr_reader :status, :data, :effects, :errors, :reconciliation

    def self.ok(data: {}, effects: [], errors: [], reconciliation: {})
      new(status: "ok", data: data, effects: effects, errors: errors, reconciliation: reconciliation)
    end

    def initialize(status:, data: {}, effects: [], errors: [], reconciliation: {})
      @status = status.to_s
      @data = normalize_hash(data)
      @effects = normalize_effects(effects)
      @errors = normalize_array(errors)
      @reconciliation = normalize_hash(reconciliation)
      validate!
    end

    def to_h
      {
        "status" => status,
        "data" => data,
        "effects" => effects,
        "errors" => errors,
        "reconciliation" => reconciliation
      }
    end

    private

    def validate!
      raise ArgumentError, "unsupported step result status: #{status}" unless STATUSES.include?(status)
    end

    def normalize_effects(value)
      Array(value).map do |effect|
        effect.respond_to?(:to_h) ? effect.to_h : normalize_hash(effect)
      end
    end

    def normalize_array(value)
      Array(value).map do |item|
        item.is_a?(Hash) ? item.transform_keys(&:to_s) : item
      end
    end

    def normalize_hash(value)
      return {} unless value.is_a?(Hash)

      value.transform_keys(&:to_s)
    end
  end
end
