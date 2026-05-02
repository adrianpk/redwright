# frozen_string_literal: true

module Redwright
  class TreeSitterStructuralExtractor
    SUPPORTED_EXTENSIONS = {
      ".rb" => :ruby,
      ".go" => :go,
      ".js" => :javascript,
      ".ts" => :typescript
    }.freeze

    def extract(project_path:, rel_path:, max_symbols: 32)
      full_path = File.join(project_path.to_s, rel_path.to_s)
      return [] unless File.file?(full_path)

      language = detect_language(rel_path)
      return [] unless language

      content = File.read(full_path)
      symbols = []
      symbols.concat(extract_imports(rel_path: rel_path, content: content, language: language))
      symbols.concat(extract_signatures(rel_path: rel_path, content: content, language: language))
      symbols.concat(extract_types(rel_path: rel_path, content: content, language: language))
      symbols.uniq { |s| [s[:path], s[:kind], s[:name], s[:signature]] }.first(max_symbols)
    rescue StandardError
      []
    end

    private

    def detect_language(rel_path)
      SUPPORTED_EXTENSIONS[File.extname(rel_path.to_s)]
    end

    def extract_imports(rel_path:, content:, language:)
      patterns = case language
      when :ruby
        [/^\s*require(?:_relative)?\s+["']([^"']+)["']/]
      when :go
        [/^\s*import\s+"([^"]+)"/, /^\s*"([^"]+)"\s*$/]
      when :javascript, :typescript
        [/^\s*import\s+.+?\s+from\s+["']([^"']+)["']/, /^\s*import\s+["']([^"']+)["']/]
      else
        []
      end

      extract_by_patterns(rel_path: rel_path, content: content, kind: "import", patterns: patterns) do |match|
        { name: match[1], signature: match[0].strip }
      end
    end

    def extract_signatures(rel_path:, content:, language:)
      patterns = case language
      when :ruby
        [/^\s*def\s+([a-zA-Z0-9_!?=]+)/, /^\s*class\s+([A-Z][A-Za-z0-9_:]*)/, /^\s*module\s+([A-Z][A-Za-z0-9_:]*)/]
      when :go
        [/^\s*func\s*(?:\([^)]*\)\s*)?([A-Za-z0-9_]+)\s*\(/]
      when :javascript, :typescript
        [/^\s*function\s+([A-Za-z0-9_]+)\s*\(/, /^\s*(?:const|let|var)\s+([A-Za-z0-9_]+)\s*=\s*\(/, /^\s*class\s+([A-Za-z0-9_]+)/]
      else
        []
      end

      extract_by_patterns(rel_path: rel_path, content: content, kind: "signature", patterns: patterns) do |match|
        { name: match[1], signature: match[0].strip }
      end
    end

    def extract_types(rel_path:, content:, language:)
      patterns = case language
      when :ruby
        [/^\s*class\s+([A-Z][A-Za-z0-9_:]*)/]
      when :go
        [/^\s*type\s+([A-Za-z0-9_]+)\s+(?:struct|interface|\w+)/]
      when :typescript
        [/^\s*type\s+([A-Za-z0-9_]+)\s*=\s*/, /^\s*interface\s+([A-Za-z0-9_]+)/]
      else
        []
      end

      extract_by_patterns(rel_path: rel_path, content: content, kind: "type", patterns: patterns) do |match|
        { name: match[1], signature: match[0].strip }
      end
    end

    def extract_by_patterns(rel_path:, content:, kind:, patterns:)
      symbols = []
      content.each_line.with_index(1) do |line, line_no|
        patterns.each do |pattern|
          match = line.match(pattern)
          next unless match

          payload = yield(match)
          symbols << {
            path: rel_path.to_s,
            line: line_no,
            kind: kind,
            name: payload[:name].to_s,
            signature: payload[:signature].to_s
          }
          break
        end
      end
      symbols
    end
  end
end
