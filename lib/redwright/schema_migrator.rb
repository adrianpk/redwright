# frozen_string_literal: true

require "sqlite3"
require "time"

module Redwright
  class SchemaMigrator
    Migration = Struct.new(:id, :description, :apply, keyword_init: true)

    DEFAULT_MIGRATIONS = [
      Migration.new(
        id: "2026_04_29_reserve_psam_dependency_and_artifact_tables",
        description: "Reserve low-frequency PSAM tables explicitly; no destructive migration applied.",
        apply: lambda { |_db|
          # Intentionally no-op: this migration records an explicit keep decision
          # for alignment_question_dependencies and alignment_artifact_links.
        }
      )
    ].freeze

    def initialize(db_path, migrations: DEFAULT_MIGRATIONS)
      @db_path = db_path
      @migrations = migrations
    end

    def run!
      with_db do |db|
        @migrations.each do |migration|
          next if applied?(db, migration.id)

          db.transaction
          begin
            migration.apply.call(db)
            mark_applied!(db, migration)
            db.commit
          rescue StandardError
            db.rollback
            raise
          end
        end
      end
    end

    private

    def applied?(db, migration_id)
      key = "migration.#{migration_id}"
      db.get_first_value("SELECT value FROM runtime_metadata WHERE key = ? LIMIT 1", [key]).to_s == "applied"
    end

    def mark_applied!(db, migration)
      now = Time.now.utc.iso8601(6)
      key = "migration.#{migration.id}"
      value = "applied"

      db.execute(
        "UPDATE runtime_metadata SET value = ?, updated_at = ? WHERE key = ?",
        [value, now, key]
      )
      if db.changes.zero?
        db.execute(
          "INSERT INTO runtime_metadata (key, value, updated_at) VALUES (?, ?, ?)",
          [key, value, now]
        )
      end

      detail_key = "migration_detail.#{migration.id}"
      detail_value = migration.description.to_s
      db.execute(
        "UPDATE runtime_metadata SET value = ?, updated_at = ? WHERE key = ?",
        [detail_value, now, detail_key]
      )
      if db.changes.zero?
        db.execute(
          "INSERT INTO runtime_metadata (key, value, updated_at) VALUES (?, ?, ?)",
          [detail_key, detail_value, now]
        )
      end
    end

    def with_db
      db = SQLite3::Database.new(@db_path)
      db.results_as_hash = false
      db.busy_timeout = 5000
      db.execute("PRAGMA foreign_keys = ON")
      yield db
    ensure
      db&.close
    end
  end
end
