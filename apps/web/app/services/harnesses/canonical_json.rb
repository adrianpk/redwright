require "json"
require "digest"

module Harnesses
  module CanonicalJson
    def self.dump(value)
      JSON.generate(order(JSON.parse(JSON.generate(value))))
    end

    def self.digest(value)
      Digest::SHA256.hexdigest(dump(value))
    end

    def self.order(value)
      case value
      when Hash then value.sort.to_h.transform_values { |item| order(item) }
      when Array then value.map { |item| order(item) }
      else value
      end
    end
    private_class_method :order
  end
end
