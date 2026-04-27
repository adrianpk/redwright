# frozen_string_literal: true

require "sqlite3"
require "time"
require_relative "trace"

module Redwright
  ActionExecutionRecord = Struct.new(
    :id, :task_id, :action_id, :action_type, :status, :stdout, :stderr, :error_message, :created_at,
    keyword_init: true
  )

  class ActionExecutionStore
    def initialize(db_path)
      @db_path = db_path
    end

    def create(task_id:, action_id:, action_type:, status:, stdout: nil, stderr: nil, error_message: nil)
      now = Time.now.utc.iso8601(6)
      id = "#{task_id}:#{action_id}:#{now}"
      with_db do |db|
        db.execute(
          <<~SQL,
            INSERT INTO action_executions (id, task_id, action_id, action_type, status, stdout, stderr, error_message, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          SQL
          [id, task_id, action_id, action_type, status, stdout, stderr, error_message, now]
        )
        Trace.sqlite(op: "insert", table: "action_executions", detail: "task_id=#{task_id} action_id=#{action_id} status=#{status}")
      end
      get(id)
    end

    def list(task_id:)
      with_db do |db|
        rows = db.execute(
          "SELECT id, task_id, action_id, action_type, status, stdout, stderr, error_message, created_at FROM action_executions WHERE task_id = ? ORDER BY created_at ASC, rowid ASC",
          [task_id]
        )
        rows.map { |row| row_to_record(row) }
      end
    end

    def get(id)
      with_db do |db|
        row = db.get_first_row(
          "SELECT id, task_id, action_id, action_type, status, stdout, stderr, error_message, created_at FROM action_executions WHERE id = ?",
          [id]
        )
        return nil unless row

        row_to_record(row)
      end
    end

    private

    def row_to_record(row)
      ActionExecutionRecord.new(
        id: row[0],
        task_id: row[1],
        action_id: row[2],
        action_type: row[3],
        status: row[4],
        stdout: row[5],
        stderr: row[6],
        error_message: row[7],
        created_at: row[8]
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
