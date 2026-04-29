# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/ingress_semantic_compatibility_adapter"

class IngressSemanticCompatibilityAdapterTest < Minitest::Test
  def test_dispatch_handles_factory_status_query
    adapter = Redwright::IngressSemanticCompatibilityAdapter.new

    result = adapter.dispatch(text: "/factory status", runtime: "interactive", actor_id: "chat-44")

    assert_equal(true, result.handled)
    assert_equal("ok", result.status)
    assert_includes(result.message, "factory_status=ready")
    assert_includes(result.message, "runtime=interactive")
  end

  def test_dispatch_skips_non_semantic_text
    adapter = Redwright::IngressSemanticCompatibilityAdapter.new

    result = adapter.dispatch(text: "implement README", runtime: "interactive", actor_id: "chat-44")

    assert_equal(false, result.handled)
    assert_equal("skip", result.status)
  end
end
