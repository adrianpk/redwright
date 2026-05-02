# frozen_string_literal: true

module Redwright
  class LspSemanticEnricher
    DEFAULT_MAX_EDGES_PER_SYMBOL = 3

    def enrich(symbols:, max_edges_per_symbol: DEFAULT_MAX_EDGES_PER_SYMBOL)
      bounded_edges = [[max_edges_per_symbol.to_i, 1].max, 8].min
      grouped = Array(symbols).group_by { |s| s[:name].to_s }

      Array(symbols).map do |symbol|
        related = grouped.fetch(symbol[:name].to_s, [])
                         .reject { |candidate| same_symbol?(symbol, candidate) }
                         .sort_by { |candidate| [candidate[:path].to_s, candidate[:line].to_i, candidate[:kind].to_s] }
                         .first(bounded_edges)

        symbol.merge(
          lsp_edges: related.map do |candidate|
            {
              edge_type: infer_edge_type(symbol: symbol, candidate: candidate),
              path: candidate[:path].to_s,
              line: candidate[:line].to_i,
              kind: candidate[:kind].to_s
            }
          end
        )
      end
    end

    private

    def same_symbol?(left, right)
      left[:path].to_s == right[:path].to_s && left[:line].to_i == right[:line].to_i && left[:kind].to_s == right[:kind].to_s
    end

    def infer_edge_type(symbol:, candidate:)
      return "type_reference" if symbol[:kind].to_s == "type" || candidate[:kind].to_s == "type"
      return "import_reference" if symbol[:kind].to_s == "import" || candidate[:kind].to_s == "import"

      "symbol_reference"
    end
  end
end
