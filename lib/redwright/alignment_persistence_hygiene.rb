# frozen_string_literal: true

require "sqlite3"

module Redwright
  class AlignmentPersistenceHygiene
    def initialize(db_path)
      @db_path = db_path
    end

    def run!
      with_db do |db|
        repair_interrupted_workstreams!(db)
        cleanup_resumed_interruptions!(db)
        assert_no_orphans!(db)
      end
    end

    private

    def repair_interrupted_workstreams!(db)
      rows = db.execute(
        <<~SQL
          SELECT i.workstream_id, i.interruption_type
          FROM alignment_interruptions i
          JOIN workstreams w ON w.id = i.workstream_id
          WHERE i.resumed_at IS NULL
        SQL
      )

      rows.each do |row|
        workstream_id = row[0]
        interruption_type = row[1]
        target_state = interruption_type == "pause" ? "suspended" : "blocked"
        db.execute("UPDATE workstreams SET state = ?, updated_at = datetime('now') WHERE id = ?", [target_state, workstream_id])
      end
    end

    def cleanup_resumed_interruptions!(db)
      db.execute("DELETE FROM alignment_interruptions WHERE resumed_at IS NOT NULL")
    end

    def assert_no_orphans!(db)
      checks = {
        "alignment_questions->workstreams" => <<~SQL,
          SELECT COUNT(*)
          FROM alignment_questions q
          LEFT JOIN workstreams w ON w.id = q.workstream_id
          WHERE w.id IS NULL
        SQL
        "alignment_answers->questions" => <<~SQL,
          SELECT COUNT(*)
          FROM alignment_answers a
          LEFT JOIN alignment_questions q ON q.id = a.question_id
          WHERE q.id IS NULL
        SQL
        "alignment_interruptions->workstreams" => <<~SQL
          SELECT COUNT(*)
          FROM alignment_interruptions i
          LEFT JOIN workstreams w ON w.id = i.workstream_id
          WHERE w.id IS NULL
        SQL
      }

      checks.each do |name, sql|
        count = db.get_first_value(sql).to_i
        next if count.zero?

        raise "persistence_hygiene_orphan_detected: #{name}=#{count}"
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
