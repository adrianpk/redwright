# frozen_string_literal: true

module Redwright
  class HintNormalizer
    Result = Struct.new(:normalized_text, :hints, keyword_init: true)

    HINT_KEYS = %w[mode scope tests ask].freeze

    def normalize(text)
      raw = text.to_s
      hints = extract_hints(raw)
      return Result.new(normalized_text: raw, hints: hints) if hints.empty?

      Result.new(
        normalized_text: merge_text_with_hints(raw, hints),
        hints: hints
      )
    end

    private

    def extract_hints(text)
      values = {}
      text.scan(/@([a-z_]+)\s*:\s*([^\n@]+)/i).each do |key, value|
        normalized_key = key.to_s.downcase
        next unless HINT_KEYS.include?(normalized_key)

        values[normalized_key] = value.to_s.strip
      end
      values
    end

    def merge_text_with_hints(text, hints)
      body = text.gsub(/@[a-z_]+\s*:\s*[^\n@]+/i, "").strip
      lines = []
      lines << body unless body.empty?
      lines << "Hint context:"
      hints.each do |k, v|
        lines << "- #{k}: #{v}"
      end
      lines.join("\n")
    end
  end
end
