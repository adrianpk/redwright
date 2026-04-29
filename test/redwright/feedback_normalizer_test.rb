# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/feedback_normalizer"

class FeedbackNormalizerTest < Minitest::Test
  Result = Struct.new(:action_id, :action_type, :status, :error_message, keyword_init: true)

  def test_normalize_collects_failures_fingerprints_and_execution_results
    normalizer = Redwright::FeedbackNormalizer.new
    quality = { failed_check_names: ["lint", "test"] }
    actions = [
      Result.new(action_id: "a1", action_type: "run_test", status: "error", error_message: "tests failed"),
      Result.new(action_id: "a2", action_type: "write_file", status: "ok", error_message: nil)
    ]

    feedback = normalizer.normalize(quality_summary: quality, action_results: actions)

    assert_equal(2, feedback.execution_results.size)
    assert_includes(feedback.normalized_failures, "test_failure:tests failed")
    assert(feedback.normalized_failures.any? { |v| v.start_with?("lint_failure:") })
    assert(feedback.fingerprints.any? { |f| f["fingerprint"].start_with?("fp-") })
  end
end
