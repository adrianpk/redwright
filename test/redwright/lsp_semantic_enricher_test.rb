# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/lsp_semantic_enricher"

class LspSemanticEnricherTest < Minitest::Test
  def test_enrich_adds_deterministic_bounded_edges
    symbols = [
      { path: "lib/a.rb", line: 10, kind: "signature", name: "parse", signature: "def parse" },
      { path: "lib/b.rb", line: 7, kind: "signature", name: "parse", signature: "def parse" },
      { path: "lib/c.rb", line: 3, kind: "signature", name: "parse", signature: "def parse" },
      { path: "lib/d.rb", line: 2, kind: "signature", name: "parse", signature: "def parse" }
    ]

    enriched = Redwright::LspSemanticEnricher.new.enrich(symbols: symbols, max_edges_per_symbol: 2)

    assert_equal symbols.size, enriched.size
    first_edges = enriched.first[:lsp_edges]
    assert_equal 2, first_edges.size
    assert_equal "lib/b.rb", first_edges[0][:path]
    assert_equal "lib/c.rb", first_edges[1][:path]
  end

  def test_enrich_uses_type_reference_edge_for_types
    symbols = [
      { path: "lib/a.rb", line: 2, kind: "type", name: "Parser", signature: "class Parser" },
      { path: "lib/b.rb", line: 4, kind: "signature", name: "Parser", signature: "def Parser" }
    ]

    enriched = Redwright::LspSemanticEnricher.new.enrich(symbols: symbols)

    assert_equal "type_reference", enriched.first[:lsp_edges][0][:edge_type]
  end
end
