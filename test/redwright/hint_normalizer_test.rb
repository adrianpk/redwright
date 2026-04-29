# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/hint_normalizer"

class HintNormalizerTest < Minitest::Test
  def test_extracts_and_merges_supported_hints
    normalizer = Redwright::HintNormalizer.new
    result = normalizer.normalize("Implement parser @mode: structured @tests: required")

    assert_includes(result.normalized_text, "Implement parser")
    assert_includes(result.normalized_text, "Hint context:")
    assert_includes(result.normalized_text, "- mode: structured")
    assert_includes(result.normalized_text, "- tests: required")
    assert_equal("structured", result.hints["mode"])
    assert_equal("required", result.hints["tests"])
  end

  def test_leaves_text_unchanged_when_no_hints
    normalizer = Redwright::HintNormalizer.new
    result = normalizer.normalize("Implement parser without hints")

    assert_equal("Implement parser without hints", result.normalized_text)
    assert_equal({}, result.hints)
  end
end
