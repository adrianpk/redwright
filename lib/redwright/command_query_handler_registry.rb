# frozen_string_literal: true

module Redwright
  class CommandQueryHandlerRegistry
    DispatchResult = Struct.new(:ok, :response, :error_code, :error_message, keyword_init: true)

    def initialize
      @handlers = {}
    end

    def register(name, &handler)
      @handlers[name.to_s] = handler
    end

    def dispatch(validated_envelope)
      handler = @handlers[validated_envelope.name.to_s]
      return error("unsupported_action", "no handler registered for #{validated_envelope.name}") unless handler

      context = ExecutionContext.new(validated_envelope.execution_context)
      response = handler.call(payload: validated_envelope.payload, context: context, request_id: validated_envelope.request_id)
      DispatchResult.new(ok: true, response: response, error_code: nil, error_message: nil)
    rescue StandardError => e
      error("execution_failed", e.message)
    end

    private

    def error(code, message)
      DispatchResult.new(ok: false, response: nil, error_code: code, error_message: message)
    end

    class ExecutionContext
      attr_reader :runtime, :role, :actor_id

      def initialize(hash)
        @runtime = hash.fetch("runtime")
        @role = hash.fetch("role")
        @actor_id = hash.fetch("actor_id")
      end
    end
  end
end
