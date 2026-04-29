# frozen_string_literal: true

require_relative "command_query_envelope_validator"
require_relative "command_query_handler_registry"

module Redwright
  class IngressSemanticCompatibilityAdapter
    Result = Struct.new(:handled, :status, :message, keyword_init: true)

    def initialize(
      envelope_validator: CommandQueryEnvelopeValidator.new,
      handler_registry: nil
    )
      @envelope_validator = envelope_validator
      @handler_registry = handler_registry || default_registry
    end

    def dispatch(text:, runtime:, actor_id:)
      envelope = build_envelope(text: text, runtime: runtime, actor_id: actor_id)
      return Result.new(handled: false, status: "skip", message: nil) unless envelope

      validated = @envelope_validator.validate(envelope)
      return Result.new(handled: true, status: "error", message: validated.errors.join(",")) unless validated.valid

      dispatched = @handler_registry.dispatch(validated)
      return Result.new(handled: true, status: "error", message: dispatched.error_message) unless dispatched.ok

      Result.new(handled: true, status: "ok", message: format_response(validated.name, dispatched.response))
    end

    private

    def build_envelope(text:, runtime:, actor_id:)
      normalized = text.to_s.strip.downcase
      return nil unless normalized == "/factory status"

      {
        "kind" => "query",
        "name" => "GetFactoryStatus",
        "payload" => {},
        "execution_context" => {
          "runtime" => runtime.to_s,
          "role" => "human_operator",
          "actor_id" => actor_id.to_s
        },
        "request_id" => "semantic-#{Time.now.to_i}"
      }
    end

    def default_registry
      registry = CommandQueryHandlerRegistry.new
      registry.register("GetFactoryStatus") do |payload:, context:, request_id:|
        {
          "status" => "ready",
          "runtime" => context.runtime,
          "actor_id" => context.actor_id,
          "request_id" => request_id
        }
      end
      registry
    end

    def format_response(name, response)
      case name
      when "GetFactoryStatus"
        "factory_status=#{response['status']} runtime=#{response['runtime']} actor_id=#{response['actor_id']}"
      else
        response.to_s
      end
    end
  end
end

