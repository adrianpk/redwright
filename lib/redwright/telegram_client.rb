# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Redwright
  class TelegramClient
    def initialize(bot_token:, http: Net::HTTP)
      @bot_token = bot_token
      @http = http
    end

    def get_updates(offset: nil, timeout_seconds: 0)
      params = { timeout: timeout_seconds.to_i }
      params[:offset] = offset if offset
      uri = URI("https://api.telegram.org/bot#{@bot_token}/getUpdates")
      uri.query = URI.encode_www_form(params)

      response = @http.get_response(uri)
      code = response.code.to_i
      raise RuntimeError, "telegram getUpdates failed: http #{response.code}" unless code >= 200 && code < 300

      payload = JSON.parse(response.body)
      raise RuntimeError, "telegram getUpdates failed: invalid payload" unless payload.is_a?(Hash) && payload["ok"] == true && payload["result"].is_a?(Array)

      payload["result"]
    rescue JSON::ParserError => e
      raise RuntimeError, "telegram getUpdates failed: invalid json (#{e.message})"
    end
  end
end
