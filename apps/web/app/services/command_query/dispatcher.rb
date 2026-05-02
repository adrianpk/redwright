module CommandQuery
  class Dispatcher
    def initialize(command_registry: Registry.new, query_registry: Registry.new)
      @command_registry = command_registry
      @query_registry = query_registry
    end

    def register_command(name, handler = nil, &block)
      @command_registry.register(name, handler, &block)
    end

    def register_query(name, handler = nil, &block)
      @query_registry.register(name, handler, &block)
    end

    def call(envelope)
      request = envelope.is_a?(Envelope) ? envelope : Envelope.from_hash(envelope)
      return invalid_envelope_result(request) unless request.valid?

      handler = registry_for(request).fetch(request.name)
      return unsupported_result(request) unless handler

      normalize_handler_result(
        request,
        handler.call(payload: request.payload, context: request.execution_context, request_id: request.request_id)
      )
    rescue StandardError => e
      Result.error(
        request_id: request_id_from(envelope),
        code: "execution_failed",
        message: e.message
      )
    end

    private

    def registry_for(request)
      request.command? ? @command_registry : @query_registry
    end

    def invalid_envelope_result(request)
      Result.error(
        request_id: request.request_id,
        code: "invalid_envelope",
        message: "command/query envelope is invalid",
        details: request.errors
      )
    end

    def unsupported_result(request)
      Result.error(
        request_id: request.request_id,
        code: "unsupported_action",
        message: "no handler registered for #{request.name}"
      )
    end

    def normalize_handler_result(request, raw_result)
      return raw_result if raw_result.is_a?(Result)

      Result.ok(
        request_id: request.request_id,
        data: raw_result.is_a?(Hash) ? raw_result : {value: raw_result}
      )
    end

    def request_id_from(envelope)
      return envelope.request_id if envelope.respond_to?(:request_id)
      return envelope["request_id"].to_s if envelope.is_a?(Hash)

      ""
    end
  end
end
