# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/skill_loader"
require "redwright/skill_registry"

class SkillLoaderTest < Minitest::Test
  def test_loads_noop_fixture_manifest
    base_dir = File.expand_path("../fixtures/skills", __dir__)
    loader = Redwright::SkillLoader.new(base_dir: base_dir)

    manifests = loader.load_all
    assert_equal(4, manifests.size)
    noop = manifests.first
    assert_equal("noop", noop.id)
    assert_equal(true, noop.enabled_by_default)
    assert_includes(noop.actions, "noop.action")
  end

  def test_loads_bootstrap_skill_contracts_and_template_sources
    base_dir = File.expand_path("../fixtures/skills", __dir__)
    loader = Redwright::SkillLoader.new(base_dir: base_dir)

    manifest = loader.load("repo-bootstrap")
    refute_nil(manifest)
    assert_equal(true, manifest.contracts["dry_run_supported"])
    assert_includes(manifest.contracts["required_fields"], "project_name")
    assert_equal(3, manifest.template_sources.size)
  end

  def test_registry_resolves_manifest_for_action
    base_dir = File.expand_path("../fixtures/skills", __dir__)
    manifests = Redwright::SkillLoader.new(base_dir: base_dir).load_all
    registry = Redwright::SkillRegistry.new(manifests: manifests)

    resolved = registry.resolve_action("noop.action")
    assert_equal("noop", resolved.id)
    assert_nil(registry.resolve_action("unknown.action"))
  end
end
