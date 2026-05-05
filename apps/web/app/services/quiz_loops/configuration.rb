module QuizLoops
  class Configuration
    DEFAULTS = {
      "max_questions" => 50,
      "max_follow_up_depth" => 3,
      "max_tags" => 3
    }.freeze

    def self.current
      new(Rails.application.config_for(:redwright_quiz))
    rescue RuntimeError
      new(DEFAULTS)
    end

    def initialize(values = {})
      @values = DEFAULTS.merge(values.to_h.transform_keys(&:to_s))
    end

    def max_questions
      positive_integer("max_questions")
    end

    def max_follow_up_depth
      positive_integer("max_follow_up_depth")
    end

    def max_tags
      positive_integer("max_tags")
    end

    private

    attr_reader :values

    def positive_integer(key)
      value = values.fetch(key).to_i
      value.positive? ? value : DEFAULTS.fetch(key)
    end
  end
end
