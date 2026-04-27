# frozen_string_literal: true

require "sqlite3"
require "time"

module Redwright
  class TaskCommitStore
    def initialize(db_path)
      @db_path = db_path
    end

    def add(task_id:, commit_sha:)
      now = utc_now
      with_db do |db|
        db.execute(
          <<~SQL,
            INSERT INTO task_commits (task_id, commit_sha, created_at)
            VALUES (?, ?, ?)
            ON CONFLICT(task_id, commit_sha) DO NOTHING
          SQL
          [task_id, commit_sha, now]
        )
      end
      list(task_id: task_id)
    end

    def list(task_id:)
      with_db do |db|
        db.execute(
          "SELECT commit_sha, created_at FROM task_commits WHERE task_id = ? ORDER BY created_at ASC, rowid ASC",
          [task_id]
        ).map do |row|
          { task_id: task_id, commit_sha: row[0], created_at: row[1] }
        end
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

    def utc_now
      Time.now.utc.iso8601(6)
    end
  end
end
