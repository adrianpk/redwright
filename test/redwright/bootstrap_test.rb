# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "minitest/autorun"
require "sqlite3"
require "yaml"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"

class BootstrapTest < Minitest::Test
  def test_bootstrap_creates_dev_workspace_directories_and_db
    Dir.mktmpdir("redwright-test-") do |dir|
      Dir.chdir(dir) do
        result = Redwright::Bootstrap.new(mode: :dev).call

        assert_path(File.join(dir, "_workspace", "redwright"), result.state_dir)
        assert_path(File.join(dir, "_workspace", "config", "redwright"), result.config_dir)
        assert_path(File.join(dir, "_workspace", "Projects"), result.projects_root)
        assert_path(File.join(dir, "_workspace", "Projects", ".worktrees"), result.worktrees_root)
        assert_path(File.join(dir, "_workspace", "redwright", "runtime.db"), result.db_path)

        assert(File.directory?(result.state_dir))
        assert(File.directory?(result.config_dir))
        assert(File.directory?(result.projects_root))
        assert(File.directory?(result.worktrees_root))
        assert(File.file?(result.db_path))
      end
    end
  end

  def test_bootstrap_rebuilds_fresh_db_after_dev_delete
    Dir.mktmpdir("redwright-test-rebuild-") do |dir|
      Dir.chdir(dir) do
        first = Redwright::Bootstrap.new(mode: :dev).call
        db_path = first.db_path
        assert(File.file?(db_path))

        FileUtils.rm_f(db_path)
        refute(File.exist?(db_path))

        second = Redwright::Bootstrap.new(mode: :dev).call
        assert(File.file?(second.db_path))

        db = SQLite3::Database.new(second.db_path)
        tables = db.execute("SELECT name FROM sqlite_master WHERE type='table'").flatten
        assert_includes(tables, "workstreams")
        assert_includes(tables, "alignments")
        assert_includes(tables, "alignment_questions")
        assert_includes(tables, "alignment_interruptions")
      ensure
        db&.close
      end
    end
  end

  def test_bootstrap_rehydrates_projects_from_manifest_after_db_reset
    Dir.mktmpdir("redwright-test-rehydrate-manifest-") do |dir|
      Dir.chdir(dir) do
        first = Redwright::Bootstrap.new(mode: :dev).call
        project_path = File.join(first.projects_root, "alpha")
        FileUtils.mkdir_p(File.join(project_path, ".redwright"))
        File.write(
          File.join(project_path, ".redwright", "manifest.yml"),
          YAML.dump(
            {
              "schema_version" => 1,
              "project" => {
                "id" => "alpha-123456",
                "name" => "alpha",
                "slug" => "alpha",
                "stack" => "ruby",
                "created_via" => "clone",
                "created_at" => "2026-04-29T00:00:00Z"
              },
              "provenance" => {
                "remote_url" => "https://example.com/acme/alpha.git",
                "provider" => "example",
                "ref" => "main"
              }
            }
          )
        )

        FileUtils.rm_f(first.db_path)
        second = Redwright::Bootstrap.new(mode: :dev).call

        store = Redwright::ProjectStore.new(second.db_path)
        project = store.resolve("alpha")
        refute_nil(project)
        assert_equal("alpha", project.name)
        assert_equal("remote_clone", project.source_type)
        assert_equal("https://example.com/acme/alpha.git", project.source_ref)
      end
    end
  end

  def test_bootstrap_uses_fallback_registration_when_manifest_is_invalid
    Dir.mktmpdir("redwright-test-rehydrate-fallback-") do |dir|
      Dir.chdir(dir) do
        first = Redwright::Bootstrap.new(mode: :dev).call
        project_path = File.join(first.projects_root, "broken")
        FileUtils.mkdir_p(File.join(project_path, ".redwright"))
        File.write(File.join(project_path, ".redwright", "manifest.yml"), "invalid: [")

        FileUtils.rm_f(first.db_path)
        second = Redwright::Bootstrap.new(mode: :dev).call

        store = Redwright::ProjectStore.new(second.db_path)
        project = store.resolve("broken")
        refute_nil(project)
        assert_equal("local_new", project.source_type)
        assert_equal("", project.source_ref)
      end
    end
  end

  private

  def assert_path(expected, actual)
    assert_equal(expected, actual)
  end
end
