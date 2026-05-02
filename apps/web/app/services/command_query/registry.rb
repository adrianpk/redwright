module CommandQuery
  class Registry
    def initialize
      @handlers = {}
    end

    def register(name, handler = nil, &block)
      normalized_name = normalize_name(name)
      callable = handler || block
      raise ArgumentError, "command_query_handler_required" unless callable.respond_to?(:call)

      @handlers[normalized_name] = callable
    end

    def fetch(name)
      @handlers[normalize_name(name)]
    end

    def registered?(name)
      @handlers.key?(normalize_name(name))
    end

    def names
      @handlers.keys.sort
    end

    private

    def normalize_name(name)
      normalized = name.to_s.strip
      raise ArgumentError, "command_query_name_required" if normalized.empty?

      normalized
    end
  end
end
