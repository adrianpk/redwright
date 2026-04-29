# frozen_string_literal: true

require "sqlite3"
require "time"
require_relative "trace"

module Redwright
  ChatContextRecord = Struct.new(:chat_id, :project_id, :workstream_id, :updated_at, keyword_init: true)

  class ChatContextStore
    def initialize(db_path)
      @db_path = db_path
    end

    def get(chat_id)
      with_db do |db|
        row = db.get_first_row(
          "SELECT chat_id, project_id, workstream_id, updated_at FROM chat_contexts WHERE chat_id = ?",
          [chat_id]
        )
        return nil unless row

        ChatContextRecord.new(
          chat_id: row[0],
          project_id: row[1],
          workstream_id: row[2],
          updated_at: row[3]
        )
      end
    end

    def upsert(chat_id:, project_id:, workstream_id:)
      now = Time.now.utc.iso8601(6)
      with_db do |db|
        db.execute(
          "UPDATE chat_contexts SET project_id = ?, workstream_id = ?, updated_at = ? WHERE chat_id = ?",
          [project_id, workstream_id, now, chat_id]
        )
        if db.changes.zero?
          db.execute(
            "INSERT INTO chat_contexts (chat_id, project_id, workstream_id, updated_at) VALUES (?, ?, ?, ?)",
            [chat_id, project_id, workstream_id, now]
          )
        end
        Trace.sqlite(op: "upsert", table: "chat_contexts", detail: "chat_id=#{chat_id}")
      end
      get(chat_id)
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
  end
end
