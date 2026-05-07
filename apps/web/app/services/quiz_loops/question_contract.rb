module QuizLoops
  class QuestionContract
    REQUIRED_FIELDS = %w[question tags follow_up_depth completion_recommended].freeze
    SENSITIVE_PATTERNS = [
      /api[-_\s]?key/i,
      /credential/i,
      /password/i,
      /private[-_\s]?key/i,
      /secret/i,
      /ssn/i,
      /token/i
    ].freeze

    Result = Struct.new(:valid, :attributes, :errors, keyword_init: true) do
      def valid?
        valid == true
      end
    end

    def initialize(max_tags: Configuration.current.max_tags, max_follow_up_depth: Configuration.current.max_follow_up_depth)
      @max_tags = max_tags
      @max_follow_up_depth = max_follow_up_depth
    end

    def validate(output)
      return invalid_result(["output must be a hash"]) unless output.is_a?(Hash)

      normalized = stringify_hash(output)
      errors = []
      errors.concat(missing_field_errors(normalized))
      errors.concat(extra_field_errors(normalized))
      errors.concat(type_errors(normalized))
      return invalid_result(errors) if errors.any?

      attributes = attributes_from(normalized)
      errors.concat(value_errors(attributes))
      errors.concat(sensitive_content_errors(attributes))
      return invalid_result(errors) if errors.any?

      Result.new(valid: true, attributes: attributes, errors: [])
    end

    private

    attr_reader :max_tags, :max_follow_up_depth

    def invalid_result(errors)
      Result.new(valid: false, attributes: {}, errors: errors)
    end

    def missing_field_errors(output)
      (REQUIRED_FIELDS - output.keys).map { |field| "missing required field: #{field}" }
    end

    def extra_field_errors(output)
      (output.keys - REQUIRED_FIELDS).map { |field| "unexpected field: #{field}" }
    end

    def type_errors(output)
      errors = []
      errors << "question must be a string" if output.key?("question") && !output["question"].is_a?(String)
      errors << "tags must be an array" if output.key?("tags") && !output["tags"].is_a?(Array)
      errors << "follow_up_depth must be an integer" if output.key?("follow_up_depth") && !output["follow_up_depth"].is_a?(Integer)
      if output.key?("completion_recommended") && !boolean?(output["completion_recommended"])
        errors << "completion_recommended must be a boolean"
      end
      errors
    end

    def attributes_from(output)
      tags = output.fetch("tags").map { |tag| Tag.normalize_name(tag) }.reject(&:blank?).uniq.first(max_tags)
      {
        "question" => output.fetch("question").to_s.strip,
        "tags" => tags,
        "follow_up_depth" => output.fetch("follow_up_depth"),
        "completion_recommended" => output.fetch("completion_recommended")
      }
    end

    def value_errors(attributes)
      errors = []
      errors << "question can't be blank" if attributes.fetch("question").blank?
      errors << "tags must include at least one normalized tag" if attributes.fetch("tags").empty?
      unless (0..max_follow_up_depth).cover?(attributes.fetch("follow_up_depth"))
        errors << "follow_up_depth must be between 0 and #{max_follow_up_depth}"
      end
      errors
    end

    def sensitive_content_errors(attributes)
      values = [attributes.fetch("question")] + attributes.fetch("tags")
      return [] unless values.any? { |value| SENSITIVE_PATTERNS.any? { |pattern| value.match?(pattern) } }

      ["question generation must not ask for secrets, credentials, tokens, passwords, private keys, or PII"]
    end

    def stringify_hash(value)
      value.each_with_object({}) do |(key, item), hash|
        hash[key.to_s] = item
      end
    end

    def boolean?(value)
      value == true || value == false
    end
  end
end
