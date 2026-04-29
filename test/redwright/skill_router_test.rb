# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/skill_router"

class SkillRouterTest < Minitest::Test
  Decision = Struct.new(:skill_requested, :skill_mode, keyword_init: true)

  def test_resolve_prefers_explicit_skill_name
    router = Redwright::SkillRouter.new
    decision = Decision.new(skill_requested: "planner-skill", skill_mode: "inferred")

    activation = router.resolve(explicit_skill_name: "grill-me", decision: decision)

    refute_nil(activation)
    assert_equal("grill-me", activation.name)
    assert_equal("explicit", activation.mode)
    assert_equal(1.0, activation.confidence)
    assert_equal("explicit_slash_skill", activation.reason)
  end

  def test_resolve_uses_inferred_planner_skill
    router = Redwright::SkillRouter.new
    decision = Decision.new(skill_requested: "repo-bootstrap", skill_mode: "inferred")

    activation = router.resolve(explicit_skill_name: "", decision: decision)

    refute_nil(activation)
    assert_equal("repo-bootstrap", activation.name)
    assert_equal("inferred", activation.mode)
    assert_equal(0.8, activation.confidence)
    assert_equal("planner_skill_inferred", activation.reason)
  end

  def test_resolve_returns_nil_when_no_skill_activation
    router = Redwright::SkillRouter.new
    decision = Decision.new(skill_requested: "", skill_mode: "none")

    activation = router.resolve(explicit_skill_name: "", decision: decision)

    assert_nil(activation)
  end
end
