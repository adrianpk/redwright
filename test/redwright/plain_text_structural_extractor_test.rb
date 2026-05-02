# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/plain_text_structural_extractor"

class PlainTextStructuralExtractorTest < Minitest::Test
  def test_extracts_symbols_with_deterministic_fallback_heuristics
    Dir.mktmpdir("redwright-plain-text-extractor-") do |dir|
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

      symbols = Redwright::PlainTextStructuralExtractor.new.extract(
        project_path: dir,
        rel_path: "lib/sample.rb"
      )

      assert(symbols.any? { |s| s[:kind] == "import" && s[:name] == "json" })
      assert(symbols.any? { |s| s[:kind] == "type" && s[:name] == "Parser" })
      assert(symbols.any? { |s| s[:kind] == "signature" && s[:name] == "parse" })
    end
  end
end
