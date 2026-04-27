# frozen_string_literal: true

require "sqlite3"
require "digest"
require "time"
require_relative "trace"

module Redwright
  TaskRecord = Struct.new(:id, :workstream_id, :trace_id, :description, :status, :created_at, :updated_at, keyword_init: true)
  TurnTraceRecord = Struct.new(
    :trace_id, :task_id, :project_id, :workstream_id, :workstream_intent, :task_status, :task_description, :created_at,
    keyword_init: true
  )

  class TaskStore
    def initialize(db_path)
      @db_path = db_path
    end

    def create(workstream_id:, description:, status: "pending", trace_id: Trace.current_trace_id)
      now = utc_now
      id = build_id(workstream_id, description, now)

      with_db do |db|
        db.execute(
          <<~SQL,
            INSERT INTO tasks (id, workstream_id, trace_id, description, status, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
          SQL
          [id, workstream_id, trace_id, description, status, now, now]
        )
        Trace.sqlite(op: "insert", table: "tasks", detail: "id=#{id}")
      end

      get(id)
    end

    def list(workstream_id: nil)
      with_db do |db|
        rows = if workstream_id
                db.execute(
                   "SELECT id, workstream_id, trace_id, description, status, created_at, updated_at FROM tasks WHERE workstream_id = ? ORDER BY updated_at DESC, rowid DESC",
                   [workstream_id]
                 )
               else
                 db.execute(
                   "SELECT id, workstream_id, trace_id, description, status, created_at, updated_at FROM tasks ORDER BY updated_at DESC, rowid DESC"
                 )
               end

        rows.map { |r| row_to_record(r) }
      end
    end

    def get(id)
      with_db do |db|
        row = db.get_first_row(
          "SELECT id, workstream_id, trace_id, description, status, created_at, updated_at FROM tasks WHERE id = ?",
          [id]
        )
        row ? row_to_record(row) : nil
      end
    end

    def list_recent_with_trace(limit: 20)
      with_db do |db|
        rows = db.execute(
          <<~SQL,
            SELECT t.trace_id, t.id, w.project_id, t.workstream_id, w.intent, t.status, t.description, t.created_at
            FROM tasks t
            JOIN workstreams w ON w.id = t.workstream_id
            WHERE t.trace_id IS NOT NULL AND t.trace_id != ''
            ORDER BY t.created_at DESC, t.rowid DESC
            LIMIT ?
          SQL
          [limit.to_i]
        )
        rows.map { |r| trace_row_to_record(r) }
      end
    end

    def list_by_trace_id(trace_id)
      with_db do |db|
        rows = db.execute(
          <<~SQL,
            SELECT t.trace_id, t.id, w.project_id, t.workstream_id, w.intent, t.status, t.description, t.created_at
            FROM tasks t
            JOIN workstreams w ON w.id = t.workstream_id
            WHERE t.trace_id = ?
            ORDER BY t.created_at ASC, t.rowid ASC
          SQL
          [trace_id]
        )
        rows.map { |r| trace_row_to_record(r) }
      end
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

    def build_id(workstream_id, description, now)
      suffix = Digest::SHA256.hexdigest("#{workstream_id}:#{description}:#{now}")[0, 6]
      "task-#{suffix}"
    end

    def row_to_record(r)
      TaskRecord.new(
        id: r[0],
        workstream_id: r[1],
        trace_id: r[2],
        description: r[3],
        status: r[4],
        created_at: r[5],
        updated_at: r[6]
      )
    end

    def trace_row_to_record(r)
      TurnTraceRecord.new(
        trace_id: r[0],
        task_id: r[1],
        project_id: r[2],
        workstream_id: r[3],
        workstream_intent: r[4],
        task_status: r[5],
        task_description: r[6],
        created_at: r[7]
      )
    end

    def utc_now
      Time.now.utc.iso8601(6)
    end
  end
end
