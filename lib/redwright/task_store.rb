# frozen_string_literal: true

require "sqlite3"
require "digest"
require "time"

module Redwright
  TaskRecord = Struct.new(:id, :workstream_id, :description, :status, :created_at, :updated_at, keyword_init: true)

  class TaskStore
    def initialize(db_path)
      @db_path = db_path
    end

    def create(workstream_id:, description:, status: "pending")
      now = utc_now
      id = build_id(workstream_id, description, now)

      with_db do |db|
        db.execute(
          <<~SQL,
            INSERT INTO tasks (id, workstream_id, description, status, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?)
          SQL
          [id, workstream_id, description, status, now, now]
        )
      end

      get(id)
    end

    def list(workstream_id: nil)
      with_db do |db|
        rows = if workstream_id
                 db.execute(
                   "SELECT id, workstream_id, description, status, created_at, updated_at FROM tasks WHERE workstream_id = ? ORDER BY updated_at DESC, rowid DESC",
                   [workstream_id]
                 )
               else
                 db.execute(
                   "SELECT id, workstream_id, description, status, created_at, updated_at FROM tasks ORDER BY updated_at DESC, rowid DESC"
                 )
               end

        rows.map { |r| row_to_record(r) }
      end
    end

    def get(id)
      with_db do |db|
        row = db.get_first_row(
          "SELECT id, workstream_id, description, status, created_at, updated_at FROM tasks WHERE id = ?",
          [id]
        )
        row ? row_to_record(row) : nil
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
        description: r[2],
        status: r[3],
        created_at: r[4],
        updated_at: r[5]
      )
    end

    def utc_now
      Time.now.utc.iso8601(6)
    end
  end
end
