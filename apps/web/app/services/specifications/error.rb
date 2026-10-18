module Specifications
  class Error < StandardError
    attr_reader :code

    def initialize(message, code: :invalid_document)
      super(message)
      @code = code
    end
  end
end
