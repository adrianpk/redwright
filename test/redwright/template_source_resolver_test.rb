# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/skill_loader"
require "redwright/template_source_resolver"

class TemplateSourceResolverTest < Minitest::Test
  def test_orders_sources_project_global_builtin
    base_dir = File.expand_path("../fixtures/skills", __dir__)
    manifest = Redwright::SkillLoader.new(base_dir: base_dir).load("repo-bootstrap")
    resolver = Redwright::TemplateSourceResolver.new

    ordered = resolver.ordered_sources(manifest)
    assert_equal(%w[project global builtin], ordered.map { |s| s["kind"] })
  end
end
