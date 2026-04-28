# frozen_string_literal: true

require "sqlite3"
require "time"

module Redwright
  InterruptionRecord = Struct.new(
    :workstream_id,
    :interruption_type,
    :reason,
    :previous_state,
    :open_question_count,
    :risk_acknowledged,
    :open_branch_snapshot,
    :created_at,
    :resumed_at,
    keyword_init: true
  )

  class AlignmentInterruptionStore
    def initialize(db_path)
      @db_path = db_path
    end

    def upsert(workstream_id:, interruption_type:, reason:, previous_state:, open_question_count:, risk_acknowledged:, open_branch_snapshot:)
      with_db do |db|
        db.execute(
          <<~SQL,
            INSERT INTO alignment_interruptions (
              workstream_id, interruption_type, reason, previous_state, open_question_count,
              risk_acknowledged, open_branch_snapshot, created_at, resumed_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NULL)
            ON CONFLICT(workstream_id) DO UPDATE SET
              interruption_type = excluded.interruption_type,
              reason = excluded.reason,
              previous_state = excluded.previous_state,
              open_question_count = excluded.open_question_count,
              risk_acknowledged = excluded.risk_acknowledged,
              open_branch_snapshot = excluded.open_branch_snapshot,
              created_at = excluded.created_at,
              resumed_at = NULL
          SQL
          [
            workstream_id, interruption_type, reason, previous_state, open_question_count,
            risk_acknowledged ? 1 : 0, open_branch_snapshot, utc_now
          ]
        )
      end
      get(workstream_id)
    end

    def get(workstream_id)
      with_db do |db|
        row = db.get_first_row(
          "SELECT workstream_id, interruption_type, reason, previous_state, open_question_count, risk_acknowledged, open_branch_snapshot, created_at, resumed_at FROM alignment_interruptions WHERE workstream_id = ?",
          [workstream_id]
        )
        row ? row_to_record(row) : nil
      end
    end

    def mark_resumed(workstream_id:)
      with_db do |db|
        db.execute(
          "UPDATE alignment_interruptions SET resumed_at = ? WHERE workstream_id = ?",
          [utc_now, workstream_id]
        )
      end
      get(workstream_id)
    end

    private

    def with_db
      db = SQLite3::Database.new(@db_path)
      db.results_as_hash = false
      db.execute("PRAGMA foreign_keys = ON")
      yield db
    ensure
      db&.close
    end

    def row_to_record(row)
      InterruptionRecord.new(
        workstream_id: row[0],
        interruption_type: row[1],
        reason: row[2],
        previous_state: row[3],
        open_question_count: row[4],
        risk_acknowledged: row[5] == 1,
        open_branch_snapshot: row[6],
        created_at: row[7],
        resumed_at: row[8]
      )
    end

    def utc_now
      Time.now.utc.iso8601(6)
    end
  end
end
