# frozen_string_literal: true

require "json"

module Redwright
  class LocalIpcProtocol
    REQUEST_TYPES = %w[send subscribe].freeze
    RESPONSE_TYPES = %w[ack error event].freeze

    def decode_request(line)
      payload = parse_json(line)
      validate_request(payload)
      payload
    end

    def encode_envelope(type:, session_id:, payload:)
      data = {
        "type" => type.to_s,
        "session_id" => session_id.to_s,
        "payload" => payload
      }
      validate_response(data)
      JSON.generate(data) + "\n"
    end

    private

    def parse_json(line)
      JSON.parse(line.to_s)
    rescue JSON::ParserError => e
      raise ArgumentError, "invalid_json:#{e.message}"
    end

    def validate_request(payload)
      raise ArgumentError, "request_not_object" unless payload.is_a?(Hash)
      type = payload["type"].to_s
      raise ArgumentError, "request_missing_type" if type.empty?
      raise ArgumentError, "request_type_not_allowed" unless REQUEST_TYPES.include?(type)

      sid = payload["session_id"].to_s
      raise ArgumentError, "request_missing_session_id" if sid.empty?
      raise ArgumentError, "request_missing_payload" unless payload.key?("payload")
      raise ArgumentError, "request_payload_not_object" unless payload["payload"].is_a?(Hash)
    end

    def validate_response(payload)
      raise ArgumentError, "response_not_object" unless payload.is_a?(Hash)
      type = payload["type"].to_s
      raise ArgumentError, "response_type_not_allowed" unless RESPONSE_TYPES.include?(type)
      raise ArgumentError, "response_missing_session_id" if payload["session_id"].to_s.empty?
      raise ArgumentError, "response_payload_not_object" unless payload["payload"].is_a?(Hash)
    end
  end
end
