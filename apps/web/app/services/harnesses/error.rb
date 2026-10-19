module Harnesses
  class Error < StandardError
    attr_reader :code, :diagnostics

    def initialize(message, code:, diagnostics: {})
      super(message)
      @code = code
      @diagnostics = diagnostics
    end
  end
end
