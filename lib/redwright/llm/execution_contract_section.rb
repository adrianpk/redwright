# frozen_string_literal: true

require_relative "context_section"

module Redwright
  module LLM
    class ExecutionContractSection
      NAME = "execution_contract"
      AUTHORITY = "execution_contract"

      def self.build(**kwargs)
        new(**kwargs).to_context_section
      end

      def initialize(content: {})
        @content = content || {}
      end

      def to_context_section
        ContextSection.new(
          name: NAME,
          content: content,
          authority: AUTHORITY,
          metadata: {high_authority: true}
        )
      end

      private

      attr_reader :content
    end
  end
end
