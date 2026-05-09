# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/tree_sitter_structural_extractor"

class TreeSitterStructuralExtractorTest < Minitest::Test
  def test_extracts_ruby_signatures_imports_and_types
    Dir.mktmpdir("redwright-struct-extractor-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(
        File.join(dir, "lib", "sample.rb"),
        <<~RUBY
          require "json"
          module Billing
            class Parser
              def parse(input)
              end
            end
          end
        RUBY
      )

      symbols = Redwright::TreeSitterStructuralExtractor.new.extract(
        project_path: dir,
        rel_path: "lib/sample.rb"
      )

      kinds = symbols.map { |s| s[:kind] }
      assert_includes(kinds, "import")
      assert_includes(kinds, "signature")
      assert_includes(kinds, "type")
      assert(symbols.any? { |s| s[:name] == "parse" && s[:kind] == "signature" })
      assert(symbols.any? { |s| s[:name] == "Parser" && s[:kind] == "type" })
    end
  end

  def test_extracts_symbols_from_broader_llm_language_set
    Dir.mktmpdir("redwright-struct-extractor-broad-") do |dir|
      FileUtils.mkdir_p(File.join(dir, "src"))
      samples = {
        "src/parser.ex" => <<~ELIXIR,
          defmodule Parser do
            def parse(input), do: input
          end
        ELIXIR
        "src/parser.gleam" => <<~GLEAM,
          import gleam/string
          pub type Parser {
            Parser
          }
          pub fn parse(input) {
            input
          }
        GLEAM
        "src/parser.cpp" => <<~CPP
          #include <string>
          class Parser {};
          int parse(std::string input) {
            return 0;
          }
        CPP
      }
      samples.each do |path, content|
        File.write(File.join(dir, path), content)
      end

      extractor = Redwright::TreeSitterStructuralExtractor.new
      symbols = samples.keys.flat_map { |path| extractor.extract(project_path: dir, rel_path: path) }

      assert(symbols.any? { |s| s[:path] == "src/parser.ex" && s[:name] == "Parser" && s[:kind] == "type" })
      assert(symbols.any? { |s| s[:path] == "src/parser.gleam" && s[:name] == "parse" && s[:kind] == "signature" })
      assert(symbols.any? { |s| s[:path] == "src/parser.cpp" && s[:name] == "string" && s[:kind] == "import" })
    end
  end
end
