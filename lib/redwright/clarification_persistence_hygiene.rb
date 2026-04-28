# frozen_string_literal: true

require "sqlite3"

module Redwright
  class ClarificationPersistenceHygiene
    DEFAULT_SESSION_TTL_SECONDS = 6 * 60 * 60

    def initialize(db_path, session_ttl_seconds: DEFAULT_SESSION_TTL_SECONDS)
      @db_path = db_path
      @session_ttl_seconds = session_ttl_seconds
    end

    def run!
      with_db do |db|
        timeout_stale_open_sessions!(db)
        cancel_orphan_open_sessions!(db)
        repair_chat_context_workstream_links!(db)
        assert_no_open_orphans!(db)
      end
    end

    private

    def timeout_stale_open_sessions!(db)
      db.execute(
        <<~SQL,
          UPDATE clarification_sessions
          SET status = 'timed_out',
              updated_at = datetime('now')
          WHERE status = 'open'
            AND datetime(updated_at) <= datetime('now', ?)
        SQL
        ["-#{@session_ttl_seconds} seconds"]
      )
    end

    def cancel_orphan_open_sessions!(db)
      db.execute(
        <<~SQL
          UPDATE clarification_sessions
          SET status = 'cancelled',
              updated_at = datetime('now')
          WHERE status = 'open'
            AND workstream_id IS NOT NULL
            AND workstream_id != ''
            AND NOT EXISTS (
              SELECT 1
              FROM workstreams w
              WHERE w.id = clarification_sessions.workstream_id
            )
        SQL
      )
    end

    def repair_chat_context_workstream_links!(db)
      db.execute(
        <<~SQL
          UPDATE chat_contexts
          SET workstream_id = NULL,
              updated_at = datetime('now')
          WHERE workstream_id IS NOT NULL
            AND (
              NOT EXISTS (
                SELECT 1
                FROM workstreams w
                WHERE w.id = chat_contexts.workstream_id
              )
              OR NOT EXISTS (
                SELECT 1
                FROM workstreams w2
                WHERE w2.id = chat_contexts.workstream_id
                  AND w2.project_id = chat_contexts.project_id
              )
            )
        SQL
      )
    end

    def assert_no_open_orphans!(db)
      checks = {
        "clarification_sessions(open)->workstreams" => <<~SQL,
          SELECT COUNT(*)
          FROM clarification_sessions s
          LEFT JOIN workstreams w ON w.id = s.workstream_id
          WHERE s.status = 'open'
            AND s.workstream_id IS NOT NULL
            AND s.workstream_id != ''
            AND w.id IS NULL
        SQL
        "chat_contexts->workstreams/project" => <<~SQL
          SELECT COUNT(*)
          FROM chat_contexts c
          LEFT JOIN workstreams w ON w.id = c.workstream_id
          WHERE c.workstream_id IS NOT NULL
            AND (
              w.id IS NULL
              OR w.project_id != c.project_id
            )
        SQL
      }

      checks.each do |name, sql|
        count = db.get_first_value(sql).to_i
        next if count.zero?

        raise "clarification_persistence_hygiene_integrity_failed: #{name}=#{count}"
      end
    end

    def with_db
      db = SQLite3::Database.new(@db_path)
      db.results_as_hash = false
      db.execute("PRAGMA foreign_keys = ON")
      yield db
    ensure
      db&.close
    end
  end
end
