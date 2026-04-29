# frozen_string_literal: true

require "tmpdir"
require "sqlite3"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/schema_migrator"

class SchemaMigratorTest < Minitest::Test
  def test_bootstrap_applies_default_migration_marker_idempotently
    Dir.mktmpdir("redwright-schema-migrator-idempotent-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        Redwright::Bootstrap.new(mode: :dev).call

        db = SQLite3::Database.new(bootstrap.db_path)
        db.results_as_hash = false
        count = db.get_first_value(
          "SELECT COUNT(*) FROM runtime_metadata WHERE key = ?",
          ["migration.2026_04_29_reserve_psam_dependency_and_artifact_tables"]
        ).to_i
        value = db.get_first_value(
          "SELECT value FROM runtime_metadata WHERE key = ?",
          ["migration.2026_04_29_reserve_psam_dependency_and_artifact_tables"]
        ).to_s
        db.close

        assert_equal(1, count)
        assert_equal("applied", value)
      end
    end
  end

  def test_migrator_rolls_back_failed_migration_and_does_not_mark_applied
    Dir.mktmpdir("redwright-schema-migrator-rollback-") do |dir|
      db_path = File.join(dir, "runtime.db")
      db = SQLite3::Database.new(db_path)
      db.execute(
        "CREATE TABLE IF NOT EXISTS runtime_metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL, updated_at TEXT NOT NULL)"
      )
      db.close

      failing = Redwright::SchemaMigrator::Migration.new(
        id: "failing_migration",
        description: "forced failure for rollback safety",
        apply: lambda { |conn|
          conn.execute("CREATE TABLE IF NOT EXISTS tmp_migration_test (id TEXT PRIMARY KEY)")
          raise "boom"
        }
      )

      err = assert_raises(RuntimeError) do
        Redwright::SchemaMigrator.new(db_path, migrations: [failing]).run!
      end
      assert_match("boom", err.message)

      db2 = SQLite3::Database.new(db_path)
      db2.results_as_hash = false
      marker = db2.get_first_value("SELECT value FROM runtime_metadata WHERE key = ?", ["migration.failing_migration"])
      table_exists = db2.get_first_value(
        "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = 'tmp_migration_test'"
      ).to_i
      db2.close

      assert_nil(marker)
      assert_equal(0, table_exists)
    end
  end
end
