require "json"
require "json_schemer"

module Harnesses
  class StructuredCall
    MAX_REQUEST_BYTES = 1024 * 1024
    MAX_SCHEMA_BYTES = 64 * 1024
    MAX_OUTPUT_BYTES = 2 * 1024 * 1024
    SCHEMA_DIALECT = "https://json-schema.org/draft/2020-12/schema".freeze

    def initialize(adapter: CodexAdapter.new)
      @adapter = adapter
    end

    def call(request)
      raise Error.new("Unsupported structured-call harness.", code: :unsupported_harness) unless request.harness == "codex"
      validate_bounds!(request)
      validator = schema_validator(request.schema)
      check_deadline!(request)
      result = @adapter.call(request)
      raise Error.new("The harness did not complete successfully.", code: :failed) unless result.outcome == :completed
      raise Error.new("The harness result is too large.", code: :output_too_large) if result.bytes.bytesize > request.max_output_bytes
      text = result.bytes.dup.force_encoding(Encoding::UTF_8)
      raise Error.new("The harness returned invalid UTF-8.", code: :invalid_output) unless text.valid_encoding?
      value = JSON.parse(text)
      raise Error.new("The harness result does not match the output schema.", code: :invalid_output) unless validator.valid?(value)
      check_deadline!(request)
      result.with(value: value)
    rescue JSON::ParserError
      raise Error.new("The harness returned invalid JSON.", code: :invalid_output)
    end

    private

    def check_deadline!(request)
      raise Error.new("The harness call timed out.", code: :timed_out) if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= request.deadline
    end

    def validate_bounds!(request)
      schema_bytes = JSON.generate(request.schema).bytesize
      raise Error.new("The output schema is too large.", code: :invalid_schema) if schema_bytes > MAX_SCHEMA_BYTES
      if request.prompt.bytesize + schema_bytes > MAX_REQUEST_BYTES
        raise Error.new("The structured request is too large.", code: :request_too_large)
      end
      unless request.timeout.is_a?(Numeric) && request.timeout.finite? && request.timeout.positive? && request.timeout <= 180 &&
          request.max_output_bytes.is_a?(Integer) && request.max_output_bytes.positive? && request.max_output_bytes <= MAX_OUTPUT_BYTES &&
          request.deadline.is_a?(Numeric) && request.deadline.finite? && request.deadline <= Process.clock_gettime(Process::CLOCK_MONOTONIC) + request.timeout &&
          (request.cancellation.nil? || request.cancellation.respond_to?(:call))
        raise Error.new("Invalid structured-call limits.", code: :invalid_request)
      end
    end

    def schema_validator(schema)
      if schema.is_a?(Hash) && schema.key?("$schema") && schema["$schema"] != SCHEMA_DIALECT
        raise Error.new("Only JSON Schema Draft 2020-12 is supported.", code: :invalid_schema)
      end
      validator = JSONSchemer.schema(schema, meta_schema: JSONSchemer.draft202012,
        insert_property_defaults: false,
        ref_resolver: proc { |_uri| raise Error.new("External schema references are disabled.", code: :invalid_schema) })
      raise Error.new("The output schema is invalid.", code: :invalid_schema) unless validator.valid_schema?
      # Resolve all schema references before a subprocess can be launched.
      validator.bundle
      validator
    rescue JSONSchemer::UnknownRef, JSONSchemer::InvalidRefResolution, JSONSchemer::InvalidRefPointer
      raise Error.new("The output schema contains an unresolved reference.", code: :invalid_schema)
    end
  end
end
