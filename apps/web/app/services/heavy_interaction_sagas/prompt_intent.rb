module HeavyInteractionSagas
  class PromptIntent
    attr_reader :kind, :slot, :question_key, :controls, :requiredness, :expected_input_shape, :locale, :llm_allowed, :metadata

    def initialize(
      kind:,
      slot: nil,
      question_key: nil,
      controls: [],
      requiredness: nil,
      expected_input_shape: nil,
      locale: nil,
      llm_allowed: nil,
      metadata: {}
    )
      @kind = kind.to_s
      @slot = string_or_nil(slot)
      @question_key = string_or_nil(question_key)
      @controls = normalize_array(controls)
      @requiredness = string_or_nil(requiredness)
      @expected_input_shape = string_or_nil(expected_input_shape)
      @locale = string_or_nil(locale)
      @llm_allowed = llm_allowed.nil? ? nil : !!llm_allowed
      @metadata = normalize_hash(metadata)
      validate!
    end

    def to_h
      {
        "kind" => kind,
        "slot" => slot,
        "question_key" => question_key,
        "controls" => controls,
        "requiredness" => requiredness,
        "expected_input_shape" => expected_input_shape,
        "locale" => locale,
        "llm_allowed" => llm_allowed,
        "metadata" => metadata
      }
    end

    private

    def validate!
      raise ArgumentError, "prompt intent kind is required" if kind.empty?
    end

    def string_or_nil(value)
      return nil if value.nil?

      value.to_s
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
