# frozen_string_literal: true

require "sqlite3"
require "time"
require_relative "trace"

module Redwright
  PlannerRejectionRecord = Struct.new(
    :id, :trace_id, :project_id, :project_ref, :reason, :raw_output, :user_text, :created_at,
    keyword_init: true
  )

  class PlannerRejectionStore
    def initialize(db_path)
      @db_path = db_path
    end

    def create(project_id:, project_ref:, reason:, raw_output:, user_text:, trace_id: Trace.current_trace_id)
      now = Time.now.utc.iso8601(6)
      id = "rej-#{now.gsub(/[^0-9]/, '')}"

      with_db do |db|
        db.execute(
          <<~SQL,
            INSERT INTO planner_rejections (id, trace_id, project_id, project_ref, reason, raw_output, user_text, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          SQL
          [id, trace_id, project_id, project_ref, reason, raw_output, user_text, now]
        )
        Trace.sqlite(op: "insert", table: "planner_rejections", detail: "id=#{id} reason=#{reason}")
      end
      get(id)
    end

    def get(id)
      with_db do |db|
        row = db.get_first_row(
          "SELECT id, trace_id, project_id, project_ref, reason, raw_output, user_text, created_at FROM planner_rejections WHERE id = ?",
          [id]
        )
        row ? row_to_record(row) : nil
      end
    end

    private

    def row_to_record(row)
      PlannerRejectionRecord.new(
        id: row[0],
        trace_id: row[1],
        project_id: row[2],
        project_ref: row[3],
        reason: row[4],
        raw_output: row[5],
        user_text: row[6],
        created_at: row[7]
      )
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
