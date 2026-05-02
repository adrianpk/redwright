module CommandQuery
  class Envelope
    KINDS = %w[command query].freeze

    attr_reader :kind, :name, :payload, :execution_context, :request_id

    def self.from_hash(hash)
      source = hash || {}
      new(
        kind: source["kind"],
        name: source["name"],
        payload: source["payload"],
        execution_context: source["execution_context"],
        request_id: source["request_id"]
      )
    end

    def initialize(kind:, name:, payload:, execution_context:, request_id:)
      @kind = kind.to_s.strip
      @name = name.to_s.strip
      @payload = payload
      @execution_context = execution_context
      @request_id = request_id.to_s.strip
    end

    def command?
      kind == "command"
    end

    def query?
      kind == "query"
    end

    def valid?
      errors.empty?
    end

    def errors
      result = []
      result << error("invalid_envelope", "kind must be command or query") unless KINDS.include?(kind)
      result << error("invalid_envelope", "name is required") if name.empty?
      result << error("invalid_payload", "payload must be an object") unless payload.is_a?(Hash)
      result << error("invalid_envelope", "execution_context must be an object") unless execution_context.is_a?(Hash)
      result << error("invalid_envelope", "request_id is required") if request_id.empty?
      result
    end

    def to_h
      {
        kind: kind,
        name: name,
        payload: payload,
        execution_context: execution_context,
        request_id: request_id
      }
    end

    private

    def error(code, message)
      {code: code, message: message}
    end
  end
end
