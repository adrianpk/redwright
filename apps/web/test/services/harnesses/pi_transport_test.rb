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
end
