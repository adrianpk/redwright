# frozen_string_literal: true

module Redwright
  module LLM
    module Redactor
      REDACTED = "[REDACTED]"
      JSON_SECRET_VALUE = /("?(?:api[_-]?key|token|password|secret|credential)"?\s*:\s*")([^"]*)(")/i
      BEARER_TOKEN = /(bearer\s+)[^\s"\\]+/i
      ASSIGNMENT_SECRET = /\b(api[_-]?key|token|password|secret|credential)=([^\s,"}]+)/i

      module_function

      def redact_text(text)
        text.to_s
          .gsub(JSON_SECRET_VALUE) { "#{$1}#{REDACTED}#{$3}" }
          .gsub(BEARER_TOKEN) { "#{$1}#{REDACTED}" }
          .gsub(ASSIGNMENT_SECRET) { "#{$1}=#{REDACTED}" }
      end
    end
  end
end
