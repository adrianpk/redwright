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

  def test_returns_nil_for_unsupported_provider
    client = Redwright::LlmClientRegistry.new.client_for("vendor-x")
    assert_nil(client)
  end

  def test_uses_provider_specific_base_url_override
    previous = ENV["DEEPSEEK_BASE_URL"]
    ENV["DEEPSEEK_BASE_URL"] = "https://proxy.example/v1"

    client = Redwright::LlmClientRegistry.new.client_for("deepseek")
    assert_equal("https://proxy.example/v1", client.instance_variable_get(:@base_url))
  ensure
    ENV["DEEPSEEK_BASE_URL"] = previous
  end

  def test_uses_provider_specific_api_key_override
    previous = ENV["KIMI_API_KEY"]
    ENV["KIMI_API_KEY"] = "kimi-key-123"

    client = Redwright::LlmClientRegistry.new.client_for("kimi")
    assert_equal("kimi-key-123", client.instance_variable_get(:@api_key))
  ensure
    ENV["KIMI_API_KEY"] = previous
  end
end
