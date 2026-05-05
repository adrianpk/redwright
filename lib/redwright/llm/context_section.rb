# frozen_string_literal: true

require "json"

module Redwright
  module LLM
    ContextSection = Struct.new(:name, :content, :authority, :metadata, keyword_init: true) do
      def bytes
        JSON.generate(content).bytesize
      rescue StandardError
        content.to_s.bytesize
      end

      def to_h
        {
          "name" => name.to_s,
          "authority" => authority.to_s,
          "bytes" => bytes,
          "metadata" => metadata || {}
        }
      end
    end
  end
end
