require "test_helper"

class HarnessesStructuredCallTest < ActiveSupport::TestCase
  SCHEMA = {
    type: "object", required: ["tickets"], additionalProperties: false,
    properties: {tickets: {type: "array", minItems: 1, maxItems: 2, items: {"$ref" => "#/$defs/ticket"}}},
    "$defs" => {ticket: {type: "object", required: %w[title priority], additionalProperties: false,
      properties: {title: {type: "string", minLength: 1}, priority: {type: "integer", enum: [1, 2]}}}}
  }.freeze

  test "host validation checks nested constraints" do
    # The adapter double isolates host schema enforcement from model behavior.
    valid = {"tickets" => [{"title" => "Deliver billing", "priority" => 1}]}
    cases = {
      "valid local reference" => [valid, true],
      "nested type" => [{"tickets" => [{"title" => 7, "priority" => 1}]}, false],
      "nested required" => [{"tickets" => [{"title" => "Missing priority"}]}, false],
      "nested enum" => [{"tickets" => [{"title" => "Unsupported", "priority" => 3}]}, false],
      "nested extra field" => [{"tickets" => [valid["tickets"].first.merge("extra" => true)]}, false],
      "empty array" => [{"tickets" => []}, false],
      "array ceiling" => [{"tickets" => valid["tickets"] * 3}, false],
      "root extra field" => [valid.merge("extra" => true), false]
    }
    cases.each do |name, (value, accepted)|
      call = Harnesses::StructuredCall.new(adapter: ->(_) { Harnesses::Result.new(bytes: JSON.generate(value)) })
      if accepted
        result = call.call(request)
        assert_equal valid, result.value, name
        assert_equal :unknown, result.usage_status
        assert_nil result.observed_model
      else
        assert_equal :invalid_output, assert_raises(Harnesses::Error, name) { call.call(request) }.code, name
      end
    end
  end

  test "schema validation never inserts defaults" do
    # A missing model value remains missing, even when a schema supplies a default.
    schema = {type: "object", required: ["name"], properties: {name: {type: "string", default: "Invented"}}}
    call = Harnesses::StructuredCall.new(adapter: ->(_) { Harnesses::Result.new(bytes: "{}") })
    assert_equal :invalid_output, assert_raises(Harnesses::Error) { call.call(request(schema: schema)) }.code
    result = call.call(request(schema: schema.except(:required)))
    assert_equal({}, result.value)
    assert_equal "{}", result.bytes
  end

  test "invalid requests fail before invocation" do
    # Unsafe schemas and limits must not launch even a successful adapter.
    invoked = false
    call = Harnesses::StructuredCall.new(adapter: ->(_) { invoked = true })
    cases = {
      "unknown harness" => [{harness: "other"}, :unsupported_harness],
      "external reference" => [{schema: {"$ref" => "https://example.invalid/schema"}}, :invalid_schema],
      "unused external reference" => [{schema: {"$defs" => {remote: {"$ref" => "file:///unavailable"}}}}, :invalid_schema],
      "wrong dialect" => [{schema: {"$schema" => "http://json-schema.org/draft-07/schema#"}}, :invalid_schema],
      "invalid schema" => [{schema: {type: "invented"}}, :invalid_schema],
      "oversized schema" => [{schema: {description: "x" * (64 * 1024)}}, :invalid_schema],
      "oversized prompt" => [{context: {body: "x" * (1024 * 1024)}}, :request_too_large],
      "no deadline" => [{timeout: 0}, :invalid_request],
      "excess deadline" => [{timeout: 181}, :invalid_request],
      "excess result limit" => [{max_output_bytes: 2 * 1024 * 1024 + 1}, :invalid_request]
    }
    cases.each do |name, (options, code)|
      assert_equal code, assert_raises(Harnesses::Error, name) { call.call(request(**options)) }.code, name
      assert_not invoked, name
    end
  end

  test "only complete bounded JSON becomes a value" do
    # A valid fragment or a failed technical outcome cannot bypass validation.
    cases = {
      "prose" => ["Before {}", :completed, :invalid_output],
      "truncated" => ["{", :completed, :invalid_output],
      "invalid utf8" => ["\xff".b, :completed, :invalid_output],
      "oversized" => [" " * 17, :completed, :output_too_large],
      "failed outcome" => ["{}", :failed, :failed]
    }
    cases.each do |name, (bytes, outcome, code)|
      call = Harnesses::StructuredCall.new(adapter: ->(_) { Harnesses::Result.new(bytes: bytes, outcome: outcome) })
      assert_equal code, assert_raises(Harnesses::Error, name) { call.call(request(schema: {}, max_output_bytes: 16)) }.code, name
    end
  end

  private

  def request(**options)
    Harnesses::Request.new(**{instructions: "Propose tickets.", context: {}, workspace: Dir.tmpdir,
      schema: SCHEMA, purpose: "slicing"}.merge(options))
  end
end
