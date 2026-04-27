# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Redwright
  class OpenAIClient
    Completion = Struct.new(:content, :finish_reason, keyword_init: true)

    def initialize(
      api_key: ENV.fetch("OPENAI_API_KEY", "").strip,
      base_url: ENV.fetch("OPENAI_BASE_URL", "https://api.openai.com/v1"),
      timeout_seconds: 120,
      http_post: nil
    )
      @api_key = api_key
      @base_url = base_url
      @timeout_seconds = timeout_seconds
      @http_post = http_post
    end

    def configured?
      !@api_key.empty?
    end

    def complete_json(model:, system_prompt:, user_text:)
      raise ArgumentError, "openai api key is missing" unless configured?

      uri = URI("#{normalized_base_url}/chat/completions")
      payload = {
        model: model,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: user_text }
        ]
      }

      response = post(uri, payload)
      code = response.code.to_i
      raise RuntimeError, "openai chat completion failed: http #{response.code}" unless code >= 200 && code < 300

      parsed = JSON.parse(response.body)
      choice = parsed.fetch("choices").first
      message = choice.fetch("message")
      content = message.fetch("content")
      finish_reason = choice["finish_reason"]
      raise RuntimeError, "openai chat completion returned empty content" if content.to_s.strip.empty?

      Completion.new(content: content, finish_reason: finish_reason)
    rescue JSON::ParserError => e
      raise RuntimeError, "openai chat completion failed: invalid json (#{e.message})"
    rescue KeyError
      raise RuntimeError, "openai chat completion failed: invalid payload"
    end

    private

    def normalized_base_url
      @base_url.sub(%r{/\z}, "")
    end

    def post(uri, payload)
      return @http_post.call(uri: uri, payload: payload, timeout_seconds: @timeout_seconds, api_key: @api_key) if @http_post

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{@api_key}"
      request.body = JSON.generate(payload)

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: @timeout_seconds) do |http|
        http.request(request)
      end
    end
  end
end
