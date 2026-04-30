# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/llm_client_registry"

class LlmClientRegistryTest < Minitest::Test
  def test_returns_client_for_known_provider
    client = Redwright::LlmClientRegistry.new.client_for("openrouter")
    assert_instance_of(Redwright::OpenAIClient, client)
    assert_equal("https://openrouter.ai/api/v1", client.instance_variable_get(:@base_url))
  end

  def test_returns_nil_for_blank_provider
    client = Redwright::LlmClientRegistry.new.client_for(" ")
    assert_nil(client)
  end
end
