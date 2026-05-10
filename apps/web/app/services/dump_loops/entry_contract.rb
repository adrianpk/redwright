module DumpLoops
  class EntryContract
    REQUIRED_FIELDS = %w[polished_input topic_heading derived_thread_hints tag_suggestions warnings].freeze
    DEFAULT_MAX_TAGS = 5
    SECRET_VALUE_PATTERNS = [
      /bearer\s+[^\s"\\]+/i,
      /\b(?:api[_-]?(?:key|token)|token|password|secret|credential)=([^\s,"}]+)/i,
      /"?(?:api[_-]?(?:key|token)|token|password|secret|credential)"?\s*:\s*"[^"]+"/i
    ].freeze

    Result = Struct.new(:valid, :attributes, :errors, keyword_init: true) do
      def valid?
        valid == true
      end
    end

    def initialize(max_tags: DEFAULT_MAX_TAGS)
      @max_tags = max_tags
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
      errors.concat(secret_value_errors(attributes))
      return invalid_result(errors) if errors.any?

      Result.new(valid: true, attributes: attributes, errors: [])
    end

    private

    attr_reader :max_tags

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
      errors << "polished_input must be a string" if output.key?("polished_input") && !output["polished_input"].is_a?(String)
      errors << "topic_heading must be a string or null" if output.key?("topic_heading") && !output["topic_heading"].nil? && !output["topic_heading"].is_a?(String)
      errors << "derived_thread_hints must be an array" if output.key?("derived_thread_hints") && !output["derived_thread_hints"].is_a?(Array)
      errors << "tag_suggestions must be an array" if output.key?("tag_suggestions") && !output["tag_suggestions"].is_a?(Array)
      errors << "warnings must be an array" if output.key?("warnings") && !output["warnings"].is_a?(Array)
      errors
    end

    def attributes_from(output)
      {
        "polished_input" => output.fetch("polished_input").to_s.strip,
        "topic_heading" => output["topic_heading"].to_s.strip.presence,
        "derived_thread_hints" => string_array(output.fetch("derived_thread_hints")),
        "tag_suggestions" => normalized_tags(output.fetch("tag_suggestions")),
        "warnings" => string_array(output.fetch("warnings"))
      }
    end

    def value_errors(attributes)
      errors = []
      errors << "polished_input can't be blank" if attributes.fetch("polished_input").blank?
      errors
    end

    def secret_value_errors(attributes)
      values = [
        attributes.fetch("polished_input"),
        attributes["topic_heading"],
        attributes.fetch("derived_thread_hints"),
        attributes.fetch("warnings")
      ].flatten.compact
      return [] unless values.any? { |value| SECRET_VALUE_PATTERNS.any? { |pattern| value.match?(pattern) } }

      ["dump polishing output must redact obvious secrets, credentials, tokens, passwords, and private keys"]
    end

    def string_array(value)
      Array(value).map(&:to_s).map(&:strip).reject(&:blank?)
    end

    def normalized_tags(value)
      string_array(value).map { |tag| Tag.normalize_name(tag) }.reject(&:blank?).uniq.first(max_tags)
    end

    def stringify_hash(value)
      value.each_with_object({}) do |(key, item), hash|
        hash[key.to_s] = item
      end
    end
  end
end
