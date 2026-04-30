# frozen_string_literal: true

require_relative "openai_client"

module Redwright
  class LlmClientRegistry
    PROVIDER_DEFAULT_BASE_URL = {
      "openai" => "https://api.openai.com/v1",
      "openrouter" => "https://openrouter.ai/api/v1",
      "deepseek" => "https://api.deepseek.com/v1",
      "kimi" => "https://api.moonshot.ai/v1"
    }.freeze

    def client_for(provider)
      key = provider.to_s.strip.downcase
      return nil if key.empty?
      return nil unless PROVIDER_DEFAULT_BASE_URL.key?(key)

      OpenAIClient.new(
        api_key: api_key_for(key),
        base_url: base_url_for(key)
      )
    end

    private

    def api_key_for(provider_key)
      provider_env = "#{provider_key.upcase}_API_KEY"
      explicit = ENV.fetch(provider_env, "").strip
      return explicit unless explicit.empty?

      return ENV.fetch("OPENAI_API_KEY", "").strip if provider_key == "openai"

      ""
    end

    def base_url_for(provider_key)
      provider_env = "#{provider_key.upcase}_BASE_URL"
      explicit = ENV.fetch(provider_env, "").strip
      return explicit unless explicit.empty?

      PROVIDER_DEFAULT_BASE_URL.fetch(provider_key, ENV.fetch("OPENAI_BASE_URL", "https://api.openai.com/v1"))
    end
  end
end
