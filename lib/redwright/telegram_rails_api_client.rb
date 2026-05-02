# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Redwright
  class TelegramRailsApiClient
    Response = Struct.new(:ok, :status_code, :body, keyword_init: true) do
      def ok?
        ok == true
      end
    end

    def initialize(base_url:, transport: nil)
      @base_url = normalize_base_url(base_url)
      @transport = transport || method(:net_http_post)
    end

    def command(name:, payload:, actor_identifier:, request_id:)
      post(
        path: "commands",
        name: name,
        payload: payload,
        actor_identifier: actor_identifier,
        request_id: request_id
      )
    end

    def query(name:, payload:, actor_identifier:, request_id:)
      post(
        path: "queries",
        name: name,
        payload: payload,
        actor_identifier: actor_identifier,
        request_id: request_id
      )
    end

    private

    def post(path:, name:, payload:, actor_identifier:, request_id:)
      body = {
        name: name.to_s,
        payload: payload.is_a?(Hash) ? payload : {},
        request_id: request_id.to_s
      }
      response = @transport.call(
        uri: URI.join("#{@base_url}/", path),
        headers: {
          "Content-Type" => "application/json",
          "X-Redwright-Actor" => actor_identifier.to_s,
          "X-Redwright-Source" => "telegram"
        },
        body: JSON.generate(body)
      )
      normalize_response(response)
    end

    def normalize_response(response)
      return Response.new(ok: true, status_code: 200, body: response) if response.is_a?(Hash)

      status_code = response.respond_to?(:code) ? response.code.to_i : 0
      raw_body = response.respond_to?(:body) ? response.body.to_s : "{}"
      parsed = JSON.parse(raw_body)
      Response.new(ok: status_code >= 200 && status_code < 300, status_code: status_code, body: parsed)
    rescue JSON::ParserError => e
      Response.new(
        ok: false,
        status_code: status_code || 0,
        body: {
          "status" => "error",
          "summary" => "Rails API returned invalid JSON.",
          "errors" => [
            {
              "code" => "invalid_json",
              "message" => e.message,
              "details" => []
            }
          ]
        }
      )
    end

    def net_http_post(uri:, headers:, body:)
      request = Net::HTTP::Post.new(uri)
      headers.each { |key, value| request[key] = value }
      request.body = body

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end
    end

    def normalize_base_url(value)
      raw = value.to_s.strip
      raise ArgumentError, "missing Rails API base URL" if raw.empty?

      raw.sub(%r{/+\z}, "")
    end
  end
end
