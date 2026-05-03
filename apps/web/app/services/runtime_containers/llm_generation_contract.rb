module RuntimeContainers
  class LlmGenerationContract
    ARRAY_FIELDS = ProjectRuntimeContainer::ARRAY_FIELDS.keys.freeze
    HASH_FIELDS = ProjectRuntimeContainer::HASH_FIELDS.keys.freeze
    STRING_FIELDS = %w[
      profile
      status
      readiness
      base_image
      runtime_name
      runtime_version
      working_directory
      validation_command
      validation_status
      validation_output_summary
    ].freeze
    REQUIRED_FIELDS = (ARRAY_FIELDS + HASH_FIELDS + STRING_FIELDS).freeze
    ASSIGNMENT_FIELDS = REQUIRED_FIELDS.freeze

    Result = Struct.new(:valid, :attributes, :errors, keyword_init: true) do
      def valid?
        valid == true
      end
    end

    def validate(output)
      return invalid_result(["output must be a hash"]) unless output.is_a?(Hash)

      normalized = stringify_hash(output)
      errors = []
      errors.concat(missing_field_errors(normalized))
      errors.concat(extra_field_errors(normalized))
      errors.concat(type_errors(normalized))
      errors.concat(state_errors(normalized))
      errors.concat(secret_value_errors(normalized))
      return invalid_result(errors) if errors.any?

      Result.new(valid: true, attributes: attributes_from(normalized), errors: [])
    end

    private

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
      ARRAY_FIELDS.each do |field|
        next if !output.key?(field) || output[field].is_a?(Array)

        errors << "#{field} must be an array"
      end
      HASH_FIELDS.each do |field|
        next if !output.key?(field) || output[field].is_a?(Hash)

        errors << "#{field} must be a hash"
      end
      STRING_FIELDS.each do |field|
        next unless output.key?(field)
        next if output[field].is_a?(String) || output[field].nil?

        errors << "#{field} must be a string or null"
      end
      errors
    end

    def state_errors(output)
      errors = []
      unless ProjectRuntimeContainer::STATUSES.include?(output["status"].to_s)
        errors << "status must be one of: #{ProjectRuntimeContainer::STATUSES.join(", ")}"
      end
      unless ProjectRuntimeContainer::READINESS_STATES.include?(output["readiness"].to_s)
        errors << "readiness must be one of: #{ProjectRuntimeContainer::READINESS_STATES.join(", ")}"
      end
      unless ProjectRuntimeContainer::VALIDATION_STATES.include?(output["validation_status"].to_s)
        errors << "validation_status must be one of: #{ProjectRuntimeContainer::VALIDATION_STATES.join(", ")}"
      end
      errors
    end

    def secret_value_errors(output)
      placeholders = output["secret_placeholders"]
      return [] unless placeholders.is_a?(Array)

      placeholders.each_with_index.filter_map do |placeholder, index|
        next unless placeholder.is_a?(Hash)

        keys = placeholder.keys.map(&:to_s)
        "secret_placeholders[#{index}] must not include a secret value" if keys.include?("value")
      end
    end

    def attributes_from(output)
      ASSIGNMENT_FIELDS.each_with_object({}) do |field, attrs|
        attrs[field.to_sym] = output[field]
      end
    end

    def stringify_hash(value)
      value.each_with_object({}) do |(key, item), hash|
        hash[key.to_s] = stringify_value(item)
      end
    end

    def stringify_value(value)
      case value
      when Hash
        stringify_hash(value)
      when Array
        value.map { |item| stringify_value(item) }
      else
        value
      end
    end
  end
end
