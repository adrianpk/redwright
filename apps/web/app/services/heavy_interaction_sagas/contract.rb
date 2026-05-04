module HeavyInteractionSagas
  class Contract
    FIELDS = %w[state stage status turns effects next_prompt_intent terminal_reason metadata].freeze

    attr_reader :state, :stage, :status, :turns, :effects, :next_prompt_intent, :terminal_reason, :metadata

    def initialize(
      state:,
      stage:,
      status:,
      turns: [],
      effects: [],
      next_prompt_intent: {},
      terminal_reason: nil,
      metadata: {}
    )
      @state = required_string(state, "state")
      @stage = required_string(stage, "stage")
      @status = required_string(status, "status")
      @turns = normalize_turns(turns)
      @effects = normalize_effects(effects)
      @next_prompt_intent = normalize_prompt_intent(next_prompt_intent)
      @terminal_reason = terminal_reason.nil? ? nil : terminal_reason.to_s
      @metadata = normalize_hash(metadata)
    end

    def to_h
      {
        "state" => state,
        "stage" => stage,
        "status" => status,
        "turns" => turns,
        "effects" => effects,
        "next_prompt_intent" => next_prompt_intent,
        "terminal_reason" => terminal_reason,
        "metadata" => metadata
      }
    end

    private

    def required_string(value, field_name)
      text = value.to_s
      raise ArgumentError, "#{field_name} is required" if text.empty?

      text
    end

    def normalize_turns(value)
      Array(value).map do |turn|
        turn.is_a?(Hash) ? turn.transform_keys(&:to_s) : {"value" => turn}
      end
    end

    def normalize_effects(value)
      Array(value).map do |effect|
        effect.respond_to?(:to_h) ? effect.to_h : normalize_hash(effect)
      end
    end

    def normalize_prompt_intent(value)
      return {} if value.nil?
      return value.to_h if value.respond_to?(:to_h)

      normalize_hash(value)
    end

    def normalize_hash(value)
      return {} unless value.is_a?(Hash)

      value.transform_keys(&:to_s)
    end
  end
end
