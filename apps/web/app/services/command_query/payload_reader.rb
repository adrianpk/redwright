module CommandQuery
  module PayloadReader
    private

    def key_present?(hash, key)
      source = hash_from(hash)
      source.key?(key.to_s) || source.key?(key.to_sym)
    end

    def value_from(hash, *keys)
      source = hash_from(hash)
      keys.each do |key|
        return source[key.to_s] if source.key?(key.to_s)
        return source[key.to_sym] if source.key?(key.to_sym)
      end
      nil
    end

    def hash_from(value)
      value.is_a?(Hash) ? value : {}
    end
  end
end
