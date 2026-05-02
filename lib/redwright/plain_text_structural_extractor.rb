# frozen_string_literal: true

module Redwright
  class PlainTextStructuralExtractor
    def extract(project_path:, rel_path:, max_symbols: 32)
      full_path = File.join(project_path.to_s, rel_path.to_s)
      return [] unless File.file?(full_path)

      symbols = []
      File.read(full_path).each_line.with_index(1) do |line, line_no|
        if (m = line.match(/^\s*require(?:_relative)?\s+["']([^"']+)["']/))
          symbols << symbol(rel_path, line_no, "import", m[1], m[0])
        elsif (m = line.match(/^\s*(?:import\s+.+?\s+from\s+["']([^"']+)["']|import\s+["']([^"']+)["'])/))
          name = m[1] || m[2]
          symbols << symbol(rel_path, line_no, "import", name, m[0])
        elsif (m = line.match(/^\s*def\s+([a-zA-Z0-9_!?=]+)/))
          symbols << symbol(rel_path, line_no, "signature", m[1], m[0])
        elsif (m = line.match(/^\s*function\s+([A-Za-z0-9_]+)\s*\(/))
          symbols << symbol(rel_path, line_no, "signature", m[1], m[0])
        elsif (m = line.match(/^\s*class\s+([A-Z][A-Za-z0-9_:]*)/))
          symbols << symbol(rel_path, line_no, "type", m[1], m[0])
        elsif (m = line.match(/^\s*module\s+([A-Z][A-Za-z0-9_:]*)/))
          symbols << symbol(rel_path, line_no, "type", m[1], m[0])
        elsif (m = line.match(/^\s*type\s+([A-Za-z0-9_]+)\s+(?:struct|interface|\w+)/))
          symbols << symbol(rel_path, line_no, "type", m[1], m[0])
        elsif (m = line.match(/^\s*(?:const|let|var)\s+([A-Za-z0-9_]+)\s*=\s*\(/))
          symbols << symbol(rel_path, line_no, "signature", m[1], m[0])
        end
      end

      symbols.uniq { |s| [s[:path], s[:line], s[:kind], s[:name], s[:signature]] }.first(max_symbols)
    rescue StandardError
      []
    end

    private

    def symbol(path, line, kind, name, signature)
      {
        path: path.to_s,
        line: line.to_i,
        kind: kind,
        name: name.to_s,
        signature: signature.to_s.strip
      }
    end
  end
end
