# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/project_manifest"

class ProjectManifestTest < Minitest::Test
  def test_accepts_schema_v1_for_new_project
    manifest = <<~YAML
      schema_version: 1
      project:
        id: "project-123"
        name: "obelix"
        slug: "obelix"
        stack: "go"
        created_via: "new"
        created_at: "2026-04-29T10:00:00Z"
    YAML

    result = Redwright::ProjectManifest.new.parse_yaml(manifest)

    assert(result.valid?)
    assert_equal("obelix", result.data.dig("project", "name"))
    assert_empty(result.errors)
  end

  def test_accepts_schema_v1_for_clone_with_provenance
    manifest = <<~YAML
      schema_version: 1
      project:
        id: "project-123"
        name: "runtime"
        slug: "runtime"
        stack: "ruby"
        created_via: "clone"
        created_at: "2026-04-29T10:00:00Z"
      provenance:
        remote_url: "https://example.com/org/runtime.git"
    YAML

    result = Redwright::ProjectManifest.new.parse_yaml(manifest)

    assert(result.valid?)
    assert_equal("https://example.com/org/runtime.git", result.data.dig("provenance", "remote_url"))
  end

  def test_rejects_unsupported_schema_version
    manifest = <<~YAML
      schema_version: 2
      project:
        id: "project-123"
        name: "runtime"
        slug: "runtime"
        stack: "ruby"
        created_via: "new"
        created_at: "2026-04-29T10:00:00Z"
    YAML

    result = Redwright::ProjectManifest.new.parse_yaml(manifest)

    refute(result.valid?)
    assert_includes(result.errors, "schema_version_unsupported: 2")
  end

  def test_rejects_clone_without_remote_url
    manifest = <<~YAML
      schema_version: 1
      project:
        id: "project-123"
        name: "runtime"
        slug: "runtime"
        stack: "ruby"
        created_via: "clone"
        created_at: "2026-04-29T10:00:00Z"
      provenance: {}
    YAML

    result = Redwright::ProjectManifest.new.parse_yaml(manifest)

    refute(result.valid?)
    assert_includes(result.errors, "provenance_remote_url_required_for_clone")
  end
end
