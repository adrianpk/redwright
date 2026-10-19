require "test_helper"
require_relative "../../support/pi_rpc_fixture"

class HarnessesPiTransportTest < ActiveSupport::TestCase
  include PiRpcFixture

  test "Pi requires containment before invocation" do
    # The normal application path has no fixture policy and must never fall back to an uncontained process.
    project = create_project
    request, = pi_request(project.root_path)
    error = assert_raises(Harnesses::Error) { Harnesses::StructuredCall.new.call(request) }
    assert_equal :unsupported_capability, error.code
    assert_not File.exist?(File.join(project.root_path, "pids"))
  end

  test "a settled final message passes host validation" do
    # Real pipes prove transport only; the sandbox collaborator admits an owned fixture executable.
    project = create_project
    request, adapter = pi_request(project.root_path)
    result = Harnesses::StructuredCall.new(adapter: adapter).call(request)
    assert_equal "Bounded output", result.value.fetch("title")
    assert_equal "fixture-provider", result.observed_provider
    assert_equal "fixture-model", result.observed_model
    assert_equal 13, result.usage.fetch("totalTokens")
    assert_equal :known, result.usage_status
    assert_equal Harnesses::CanonicalJson.digest(request.binding), result.binding_digest
    assert File.exist?(File.join(project.root_path, "cleaned"))
    File.readlines(File.join(project.root_path, "pids")).each do |pid|
      assert_raises(Errno::ESRCH) { Process.kill(0, Integer(pid)) }
    end
  end

  test "setup and host schema failures cannot return a result" do
    # These failures cross real subprocess pipes and never use a live provider.
    {"wrong-version" => :unsupported_version, "wrong-id" => :protocol_error,
      "wrong-model" => :protocol_error, "rejected" => :provider_error,
      "invalid-schema" => :invalid_output}.each do |scenario, code|
      project = create_project(key: "fixture-#{scenario}")
      request, adapter = pi_request(project.root_path, scenario: scenario)
      error = assert_raises(Harnesses::Error, scenario) { Harnesses::StructuredCall.new(adapter: adapter).call(request) }
      assert_equal code, error.code, scenario
      assert_not_includes error.message + error.diagnostics.to_json, "private fixture provider detail"
    end
  end

  test "split and interleaved records retain final evidence" do
    # Pipe chunks and Unicode separators do not define JSONL record boundaries; event ordering may precede the acknowledgment.
    %w[split crlf interleaved events-before-ack].each do |scenario|
      project = create_project(key: "fixture-#{scenario}")
      request, adapter = pi_request(project.root_path, scenario: scenario)
      result = Harnesses::StructuredCall.new(adapter: adapter).call(request)
      assert_equal "Behavior \u2028 remains \u2029 bounded. ☃", result.value.fetch("body"), scenario
      assert_not_includes result.bytes, "partial, never final"
      assert_fixture_reaped(project.root_path)
    end
  end

  test "invalid RPC work cannot publish a final result" do
    # Exercise framing, correlation, ownership, final settlement and host validation through real pipes.
    scenarios = {
      "invalid-utf8" => :protocol_error, "malformed" => :protocol_error, "early-exit" => :protocol_error,
      "truncated" => :protocol_error, "end-only" => :protocol_error, "late-error" => :protocol_error,
      "duplicate-final" => :protocol_error, "wrong-final-model" => :protocol_error, "busy-final" => :protocol_error,
      "persisted-session" => :protocol_error, "invalid-usage" => :protocol_error, "retry" => :protocol_error,
      "handled" => :protocol_error, "queued" => :protocol_error, "nonzero" => :failed,
      "tool" => :unsupported_capability, "tool-block" => :unsupported_capability, "ui" => :unsupported_capability,
      "unsupported-thinking" => :unsupported_capability, "wrong-thinking" => :unsupported_capability,
      "provider-error" => :provider_error, "aborted" => :cancelled, "invalid-result" => :invalid_output
    }
    scenarios.each do |scenario, code|
      project = create_project(key: "fixture-#{scenario}")
      request, adapter = pi_request(project.root_path, scenario: scenario)
      error = assert_raises(Harnesses::Error, scenario) { Harnesses::StructuredCall.new(adapter: adapter).call(request) }
      assert_equal code, error.code, scenario
      assert_not_includes error.message + error.diagnostics.to_json, "private fixture provider detail"
      assert_fixture_reaped(project.root_path)
    end
  end

  test "incomplete or unexited calls reach the deadline" do
    # An acknowledgment, agent_end or idle state alone is not completion of the owned process.
    %w[ack-only no-settlement hang-after-idle].each do |scenario|
      project = create_project(key: "fixture-#{scenario}")
      request, adapter = pi_request(project.root_path, scenario: scenario, timeout: 1)
      error = assert_raises(Harnesses::Error, scenario) { Harnesses::StructuredCall.new(adapter: adapter).call(request) }
      assert_equal :timed_out, error.code, scenario
      assert_fixture_reaped(project.root_path)
    end
  end

  test "cancellation cleans up after prompt admission" do
    # Environment scrubbing and cancellation cross the subprocess boundary after the prompt is admitted.
    project = create_project
    request, adapter = pi_request(project.root_path, scenario: "ack-only",
      cancellation: -> { File.exist?(File.join(project.root_path, "prompted")) })
    prior_secret = ENV["UNRELATED_FIXTURE_SECRET"]
    ENV["UNRELATED_FIXTURE_SECRET"] = "owned fixture sentinel"
    error = assert_raises(Harnesses::Error) { Harnesses::StructuredCall.new(adapter: adapter).call(request) }
    assert_equal :cancelled, error.code
    assert_fixture_reaped(project.root_path)
  ensure
    ENV["UNRELATED_FIXTURE_SECRET"] = prior_secret
  end

  test "missing and partial usage stays unknown or partial" do
    # Provider counters remain measured evidence, while an explicitly observed model is kept separately from the binding.
    {"missing-usage" => :unknown, "partial-usage" => :partial, "observed-model" => :known}.each do |scenario, status|
      project = create_project(key: "fixture-#{scenario}")
      request, adapter = pi_request(project.root_path, scenario: scenario)
      result = Harnesses::StructuredCall.new(adapter: adapter).call(request)
      assert_equal status, result.usage_status
      assert_nil result.usage if status == :unknown
      assert_equal({"output" => 3}, result.usage) if status == :partial
      assert_equal "observed-model", result.observed_model if scenario == "observed-model"
      assert_equal "fixture-model", request.binding.fetch("requested_model")
    end
  end

  test "encoded records admit the decoded result ceiling" do
    # Two escaped records each below 16 MiB carry a 2 MiB result; encoded bytes are not the result bound.
    project = create_project
    request, adapter = pi_request(project.root_path, scenario: "encoded-max", schema: {"type" => "object"}, timeout: 10)
    result = Harnesses::StructuredCall.new(adapter: adapter).call(request)
    assert_equal 2 * 1024 * 1024, result.bytes.bytesize
    assert_equal({}, result.value)
    assert_operator result.diagnostics.fetch("stdout").fetch("bytes"), :>, 24 * 1024 * 1024 - 1024
    assert_fixture_reaped(project.root_path)

    request, adapter = pi_request(project.root_path, scenario: "encoded-max", schema: {"type" => "object"},
      timeout: 10, max_output_bytes: 4096)
    error = assert_raises(Harnesses::Error) { Harnesses::StructuredCall.new(adapter: adapter).call(request) }
    assert_equal :output_too_large, error.code
    assert_fixture_reaped(project.root_path)
  end

  test "oversized records and encoded input are rejected" do
    # The record cap bounds framing memory; JSON escaping must count against the request cap before launch.
    project = create_project
    request, adapter = pi_request(project.root_path, scenario: "record-limit")
    error = assert_raises(Harnesses::Error) { Harnesses::StructuredCall.new(adapter: adapter).call(request) }
    assert_equal :protocol_error, error.code
    assert_fixture_reaped(project.root_path)
    File.delete(File.join(project.root_path, "pids"))

    request, adapter = pi_request(project.root_path, instructions: "\u0001" * 200_000)
    error = assert_raises(Harnesses::Error) { Harnesses::StructuredCall.new(adapter: adapter).call(request) }
    assert_equal :request_too_large, error.code
    assert_not File.exist?(File.join(project.root_path, "pids"))

    request, adapter = pi_request(project.root_path)
    request, adapter = pi_request(project.root_path, binding: request.binding.merge("schema_digest" => "changed"))
    error = assert_raises(Harnesses::Error) { Harnesses::StructuredCall.new(adapter: adapter).call(request) }
    assert_equal :invalid_binding, error.code
    assert_not File.exist?(File.join(project.root_path, "pids"))
  end

  private

  def assert_fixture_reaped(root)
    assert File.exist?(File.join(root, "cleaned"))
    File.readlines(File.join(root, "pids")).each do |pid|
      assert_raises(Errno::ESRCH) { Process.kill(0, Integer(pid)) }
    end
  end
end
