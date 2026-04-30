# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright"

class CliLlmClientTest < Minitest::Test
  def test_llm_client_for_openai_returns_openai_client
    cli = Redwright::CLI.new(["daemon", "run", "--dev", "--once", "--ingress", "none"])
    client = cli.send(:llm_client_for, "openai")
    assert_instance_of(Redwright::OpenAIClient, client)
  end

  def test_llm_client_for_unsupported_provider_returns_nil
    cli = Redwright::CLI.new(["daemon", "run", "--dev", "--once", "--ingress", "none"])
    client = cli.send(:llm_client_for, "vendor-x")
    assert_nil(client)
  end
end
