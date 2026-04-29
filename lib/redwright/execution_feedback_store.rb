# frozen_string_literal: true

require "sqlite3"
require "json"
require "securerandom"
require "time"
require_relative "trace"

module Redwright
  class ExecutionFeedbackStore
    def initialize(db_path)
      @db_path = db_path
    end

    def create(trace_id:, workstream_id:, task_id:, attempt:, failure_class:, fingerprint:, details:)
      now = Time.now.utc.iso8601(6)
      id = "efd-#{SecureRandom.hex(6)}"
      with_db do |db|
        db.execute(
          <<~SQL,
            INSERT INTO execution_feedbacks (
              id, trace_id, workstream_id, task_id, attempt, failure_class, fingerprint, details_json, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          SQL
          [id, trace_id, workstream_id, task_id, attempt.to_i, failure_class, fingerprint, JSON.generate(details || {}), now]
        )
        Trace.sqlite(op: "insert", table: "execution_feedbacks", detail: "id=#{id} task_id=#{task_id}")
      end
      id
    end

    def list_for_trace(trace_id, limit: 20)
      with_db do |db|
        db.execute(
          <<~SQL,
            SELECT failure_class, fingerprint, details_json
            FROM execution_feedbacks
            WHERE trace_id = ?
            ORDER BY created_at DESC, rowid DESC
            LIMIT ?
          SQL
          [trace_id.to_s, limit.to_i]
        ).map do |row|
          {
            "failure_class" => row[0].to_s,
            "fingerprint" => row[1].to_s,
            "details" => parse_json(row[2])
          }
        end
      end
    end

    private

    def parse_json(raw)
      parsed = JSON.parse(raw.to_s)
      parsed.is_a?(Hash) ? parsed : {}
    rescue JSON::ParserError
      {}
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
