# frozen_string_literal: true

require "sqlite3"
require "time"

module Redwright
  class RuntimeConfigStore
    KEY_BLOCKED_RETRY_ATTEMPTS = "blocked_retry_attempts"

    def initialize(db_path)
      @db_path = db_path
    end

    def blocked_retry_attempts
      value = fetch(KEY_BLOCKED_RETRY_ATTEMPTS)
      return 1 if value.nil? || value.empty?

      parsed = Integer(value, 10)
      parsed.positive? ? parsed : 1
    rescue ArgumentError
      1
    end

    def set_blocked_retry_attempts(value)
      parsed = Integer(value)
      raise ArgumentError, "blocked_retry_attempts must be >= 1" if parsed < 1

      upsert(KEY_BLOCKED_RETRY_ATTEMPTS, parsed.to_s)
      parsed
    rescue ArgumentError
      raise ArgumentError, "blocked_retry_attempts must be >= 1"
    end

    private

    def fetch(key)
      with_db do |db|
        row = db.get_first_row("SELECT value FROM runtime_metadata WHERE key = ?", [key])
        row&.first
      end
    end

    def upsert(key, value)
      now = Time.now.utc.iso8601(6)
      with_db do |db|
        db.execute(
          <<~SQL,
            INSERT INTO runtime_metadata (key, value, updated_at)
            VALUES (?, ?, ?)
            ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at
          SQL
          [key, value, now]
        )
      end
    end

    def with_db
      db = SQLite3::Database.new(@db_path)
      db.results_as_hash = false
      yield db
    ensure
      db&.close
    end
  end
end
