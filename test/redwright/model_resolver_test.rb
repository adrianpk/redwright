# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/app_config"
require "redwright/model_resolver"

class ModelResolverTest < Minitest::Test
  def test_resolve_returns_first_candidate_for_role
    config = Redwright::ModelsConfig.new(
      coding: Redwright::ModelRoleConfig.new(
        candidates: [
          Redwright::ModelCandidate.new(provider: "openai", name: "gpt-5.2"),
          Redwright::ModelCandidate.new(provider: "openai", name: "gpt-5-mini")
        ]
      ),
      non_coding: Redwright::ModelRoleConfig.new(
        candidates: [Redwright::ModelCandidate.new(provider: "openai", name: "gpt-5-mini")]
      )
    )

    resolver = Redwright::ModelResolver.new(config)
    resolved = resolver.resolve("coding")

    assert_equal("openai", resolved.provider)
    assert_equal("gpt-5.2", resolved.name)
  end

  def test_unknown_role_raises
    config = Redwright::ModelsConfig.new(
      coding: Redwright::ModelRoleConfig.new(candidates: [Redwright::ModelCandidate.new(provider: "openai", name: "a")]),
      non_coding: Redwright::ModelRoleConfig.new(candidates: [Redwright::ModelCandidate.new(provider: "openai", name: "b")])
    )

    resolver = Redwright::ModelResolver.new(config)
    err = assert_raises(ArgumentError) { resolver.resolve("other") }
    assert_match("unknown model role", err.message)
  end
end
