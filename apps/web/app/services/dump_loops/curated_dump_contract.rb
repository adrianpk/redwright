module DumpLoops
  class CuratedDumpContract
    REQUIRED_FIELDS = %w[
      central_topic
      summary
      key_concepts
      decisions_or_preferences
      tensions_and_tradeoffs
      assumptions
      derived_threads
      possible_downstream_artifacts
      open_questions
      tag_suggestions
    ].freeze
    DEFAULT_MAX_TAGS = 8

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
      errors << "central_topic must be a string" if output.key?("central_topic") && !output["central_topic"].is_a?(String)
      errors << "summary must be a string" if output.key?("summary") && !output["summary"].is_a?(String)
      list_fields.each do |field|
        errors << "#{field} must be an array" if output.key?(field) && !output[field].is_a?(Array)
      end
      errors
    end

    def attributes_from(output)
      {
        "central_topic" => output.fetch("central_topic").to_s.strip,
        "summary" => output.fetch("summary").to_s.strip,
        "key_concepts" => string_array(output.fetch("key_concepts")),
        "decisions_or_preferences" => string_array(output.fetch("decisions_or_preferences")),
        "tensions_and_tradeoffs" => string_array(output.fetch("tensions_and_tradeoffs")),
        "assumptions" => string_array(output.fetch("assumptions")),
        "derived_threads" => string_array(output.fetch("derived_threads")),
        "possible_downstream_artifacts" => string_array(output.fetch("possible_downstream_artifacts")),
        "open_questions" => string_array(output.fetch("open_questions")),
        "tag_suggestions" => normalized_tags(output.fetch("tag_suggestions"))
      }
    end

    def value_errors(attributes)
      errors = []
      errors << "central_topic can't be blank" if attributes.fetch("central_topic").blank?
      errors << "summary can't be blank" if attributes.fetch("summary").blank?
      errors
    end

    def list_fields
      REQUIRED_FIELDS - %w[central_topic summary]
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
