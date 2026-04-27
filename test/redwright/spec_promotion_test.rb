# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/spec_promotion"

class SpecPromotionTest < Minitest::Test
  def test_promote_copies_draft_to_specs_with_normalized_name
    Dir.mktmpdir("redwright-spec-promotion-test-") do |dir|
      drafts = File.join(dir, "ops", "specs", "drafts")
      FileUtils.mkdir_p(drafts)
      File.write(File.join(drafts, "2026-04-27-runtime-proto-spec-draft.md"), "draft body\n")

      promoter = Redwright::SpecPromotion.new(base_dir: dir)
      result = promoter.promote("2026-04-27-runtime-proto-spec-draft.md")

      assert(File.file?(result.source_path))
      assert(File.file?(result.target_path))
      assert(result.target_path.end_with?("2026-04-27-runtime-proto-spec.md"))
      assert_equal("draft body\n", File.read(result.target_path))
    end
  end

  def test_promote_missing_file_raises
    Dir.mktmpdir("redwright-spec-promotion-missing-") do |dir|
      promoter = Redwright::SpecPromotion.new(base_dir: dir)
      err = assert_raises(ArgumentError) { promoter.promote("missing.md") }
      assert_match("draft spec not found", err.message)
    end
  end
end
