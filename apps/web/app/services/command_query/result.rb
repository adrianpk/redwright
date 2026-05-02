module CommandQuery
  class Result
    STATUSES = %w[ok error].freeze

    attr_reader :status, :request_id, :data, :effects, :errors

    def self.ok(request_id:, data: {}, effects: [])
      new(status: "ok", request_id: request_id, data: data, effects: effects, errors: [])
    end

    def self.error(request_id:, code:, message:, details: [])
      new(
        status: "error",
        request_id: request_id,
        data: {},
        effects: [],
        errors: [{code: code.to_s, message: message.to_s, details: details}]
      )
    end

    def initialize(status:, request_id:, data:, effects:, errors:)
      @status = status.to_s
      @request_id = request_id.to_s
      @data = data.is_a?(Hash) ? data : {value: data}
      @effects = effects.is_a?(Array) ? effects : Array(effects)
      @errors = errors.is_a?(Array) ? errors : Array(errors)
    end

    def ok?
      status == "ok"
    end

    def error?
      status == "error"
    end

    def to_h
      {
        status: status,
        request_id: request_id,
        data: data,
        effects: effects,
        errors: errors
      }
    end
  end
end
