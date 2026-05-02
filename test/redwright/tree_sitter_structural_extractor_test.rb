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
end
