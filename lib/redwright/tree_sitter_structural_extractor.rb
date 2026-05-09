# frozen_string_literal: true

module Redwright
  class TreeSitterStructuralExtractor
    SUPPORTED_EXTENSIONS = {
      ".rb" => :ruby,
      ".go" => :go,
      ".js" => :javascript,
      ".jsx" => :javascript,
      ".ts" => :typescript,
      ".tsx" => :typescript,
      ".py" => :python,
      ".rs" => :rust,
      ".zig" => :zig,
      ".ex" => :elixir,
      ".exs" => :elixir,
      ".gleam" => :gleam,
      ".java" => :java,
      ".kt" => :kotlin,
      ".kts" => :kotlin,
      ".cs" => :csharp,
      ".c" => :c,
      ".h" => :c,
      ".cc" => :cpp,
      ".cpp" => :cpp,
      ".cxx" => :cpp,
      ".hpp" => :cpp,
      ".php" => :php
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
      when :python
        [/^\s*import\s+([A-Za-z0-9_.]+)/, /^\s*from\s+([A-Za-z0-9_.]+)\s+import\s+/]
      when :rust
        [/^\s*use\s+([^;]+);/]
      when :elixir
        [/^\s*(?:alias|import|require|use)\s+([A-Za-z0-9_.]+)/]
      when :gleam
        [/^\s*import\s+([a-zA-Z0-9_\/.]+)/]
      when :java, :kotlin
        [/^\s*import\s+([^;]+);?/]
      when :c, :cpp
        [/^\s*#include\s+[<"]([^>"]+)[>"]/]
      when :php
        [/^\s*use\s+([^;]+);/]
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
      when :python
        [/^\s*def\s+([A-Za-z0-9_]+)\s*\(/, /^\s*class\s+([A-Za-z0-9_]+)/]
      when :rust
        [/^\s*(?:pub\s+)?fn\s+([A-Za-z0-9_]+)\s*\(/]
      when :zig
        [/^\s*(?:pub\s+)?fn\s+([A-Za-z0-9_]+)\s*\(/]
      when :elixir
        [/^\s*def(?:p)?\s+([a-zA-Z0-9_!?]+)\s*(?:\(|do:)/, /^\s*defmodule\s+([A-Za-z0-9_.]+)/]
      when :gleam
        [/^\s*pub\s+fn\s+([a-zA-Z0-9_]+)\s*\(/, /^\s*fn\s+([a-zA-Z0-9_]+)\s*\(/]
      when :java, :kotlin, :csharp
        [/^\s*(?:public|private|protected|internal|static|final|override|suspend|\s)+\s*[A-Za-z0-9_<>,\[\]?]+\s+([A-Za-z0-9_]+)\s*\(/, /^\s*(?:public\s+)?(?:class|interface|enum|record)\s+([A-Za-z0-9_]+)/]
      when :c, :cpp
        [/^\s*(?:[A-Za-z_][A-Za-z0-9_:<>\*&\s]+)\s+([A-Za-z_][A-Za-z0-9_:]*)\s*\([^;]*\)\s*(?:\{|;)?\s*$/]
      when :php
        [/^\s*function\s+([A-Za-z0-9_]+)\s*\(/, /^\s*class\s+([A-Za-z0-9_]+)/]
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
      when :python
        [/^\s*class\s+([A-Za-z0-9_]+)/]
      when :rust
        [/^\s*(?:pub\s+)?(?:struct|enum|trait)\s+([A-Za-z0-9_]+)/]
      when :zig
        [/^\s*const\s+([A-Za-z0-9_]+)\s*=\s*(?:struct|enum|union)/]
      when :elixir
        [/^\s*defmodule\s+([A-Za-z0-9_.]+)/]
      when :gleam
        [/^\s*pub\s+type\s+([A-Za-z0-9_]+)/, /^\s*type\s+([A-Za-z0-9_]+)/]
      when :java, :kotlin, :csharp
        [/^\s*(?:public\s+)?(?:class|interface|enum|record|data\s+class)\s+([A-Za-z0-9_]+)/]
      when :c, :cpp
        [/^\s*(?:typedef\s+)?(?:struct|class|enum)\s+([A-Za-z0-9_]+)/]
      when :php
        [/^\s*(?:final\s+)?(?:class|interface|trait|enum)\s+([A-Za-z0-9_]+)/]
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
