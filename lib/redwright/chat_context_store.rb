# frozen_string_literal: true

require "sqlite3"
require "time"
require_relative "trace"
require_relative "persistence_contract_error"

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
        ensure_project_exists!(db, project_id: project_id)
        ensure_workstream_consistency!(db, workstream_id: workstream_id, project_id: project_id)
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

    def ensure_project_exists!(db, project_id:)
      exists = db.get_first_value("SELECT 1 FROM projects WHERE id = ? LIMIT 1", [project_id]).to_i == 1
      return if exists

      raise PersistenceContractError, "invalid_project_reference: #{project_id}"
    end

    def ensure_workstream_consistency!(db, workstream_id:, project_id:)
      return if workstream_id.nil? || workstream_id.to_s.strip.empty?

      row = db.get_first_row("SELECT project_id FROM workstreams WHERE id = ? LIMIT 1", [workstream_id])
      raise PersistenceContractError, "invalid_workstream_reference: #{workstream_id}" if row.nil?
      return if row[0].to_s == project_id.to_s

      raise PersistenceContractError,
            "cross_project_workstream_reference: workstream=#{workstream_id} workstream_project=#{row[0]} context_project=#{project_id}"
    end
  end
end
