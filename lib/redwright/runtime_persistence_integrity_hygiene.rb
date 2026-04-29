# frozen_string_literal: true

require "sqlite3"

module Redwright
  class RuntimePersistenceIntegrityHygiene
    def initialize(db_path)
      @db_path = db_path
    end

    def run!
      with_db do |db|
        nullify_orphan_clarification_workstream_links!(db)
        nullify_orphan_planner_rejection_project_links!(db)
        assert_no_orphaned_critical_links!(db)
      end
    end

    private

    def nullify_orphan_clarification_workstream_links!(db)
      db.execute(
        <<~SQL
          UPDATE clarification_sessions
          SET workstream_id = NULL,
              updated_at = datetime('now')
          WHERE workstream_id IS NOT NULL
            AND workstream_id != ''
            AND NOT EXISTS (
              SELECT 1
              FROM workstreams w
              WHERE w.id = clarification_sessions.workstream_id
            )
        SQL
      )
    end

    def nullify_orphan_planner_rejection_project_links!(db)
      db.execute(
        <<~SQL
          UPDATE planner_rejections
          SET project_id = NULL
          WHERE project_id IS NOT NULL
            AND project_id != ''
            AND NOT EXISTS (
              SELECT 1
              FROM projects p
              WHERE p.id = planner_rejections.project_id
            )
        SQL
      )
    end

    def assert_no_orphaned_critical_links!(db)
      checks = {
        "tasks->workstreams" => <<~SQL,
          SELECT COUNT(*)
          FROM tasks t
          LEFT JOIN workstreams w ON w.id = t.workstream_id
          WHERE w.id IS NULL
        SQL
        "action_executions->tasks" => <<~SQL,
          SELECT COUNT(*)
          FROM action_executions a
          LEFT JOIN tasks t ON t.id = a.task_id
          WHERE t.id IS NULL
        SQL
        "workstreams->projects" => <<~SQL
          SELECT COUNT(*)
          FROM workstreams w
          LEFT JOIN projects p ON p.id = w.project_id
          WHERE p.id IS NULL
        SQL
      }

      checks.each do |name, sql|
        count = db.get_first_value(sql).to_i
        next if count.zero?

        raise "runtime_persistence_integrity_failed: #{name}=#{count}"
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
