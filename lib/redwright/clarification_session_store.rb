# frozen_string_literal: true

require "sqlite3"
require "json"
require "digest"
require "time"
require_relative "trace"
require_relative "persistence_contract_error"

module Redwright
  ClarificationSessionRecord = Struct.new(
    :id,
    :chat_id,
    :workstream_id,
    :status,
    :gap_type,
    :payload,
    :resolved_fields,
    :last_question_id,
    :turn_counter,
    :created_at,
    :updated_at,
    keyword_init: true
  )

  class ClarificationSessionStore
    STATUSES = %w[open closed cancelled timed_out].freeze

    def initialize(db_path)
      @db_path = db_path
    end

    def get_open(chat_id:, workstream_id: nil)
      with_db do |db|
        row = if workstream_id.nil?
                db.get_first_row(
                  "SELECT id, chat_id, workstream_id, status, gap_type, payload_json, resolved_fields_json, last_question_id, turn_counter, created_at, updated_at FROM clarification_sessions WHERE chat_id = ? AND status = 'open' ORDER BY updated_at DESC, rowid DESC LIMIT 1",
                  [chat_id]
                )
              else
                db.get_first_row(
                  "SELECT id, chat_id, workstream_id, status, gap_type, payload_json, resolved_fields_json, last_question_id, turn_counter, created_at, updated_at FROM clarification_sessions WHERE chat_id = ? AND workstream_id = ? AND status = 'open' ORDER BY updated_at DESC, rowid DESC LIMIT 1",
                  [chat_id, workstream_id]
                )
              end
        row_to_record(row)
      end
    end

    def open_project_name_confirm(chat_id:, workstream_id:, suggested_project_name:, question_id: nil)
      now = utc_now
      session_id = build_id(chat_id: chat_id, workstream_id: workstream_id, now: now)
      payload = { "suggested_project_name" => suggested_project_name.to_s }

      with_db do |db|
        ensure_workstream_exists!(db, workstream_id: workstream_id)
        tx_started = false
        db.transaction
        tx_started = true
        close_open_for_chat!(db, chat_id: chat_id)
        db.execute(
          "INSERT INTO clarification_sessions (id, chat_id, workstream_id, status, gap_type, payload_json, resolved_fields_json, last_question_id, turn_counter, created_at, updated_at) VALUES (?, ?, ?, 'open', ?, ?, ?, ?, 0, ?, ?)",
          [session_id, chat_id, workstream_id, "project_name_confirm", JSON.generate(payload), JSON.generate({}), question_id, now, now]
        )
        db.commit
        Trace.sqlite(op: "insert", table: "clarification_sessions", detail: "id=#{session_id} status=open")
      rescue StandardError
        db.rollback if tx_started
        raise
      end

      get_open(chat_id: chat_id, workstream_id: workstream_id)
    end

    def open_planner_gap(chat_id:, workstream_id:, base_message:, gap:, question_id: nil)
      now = utc_now
      session_id = build_id(chat_id: chat_id, workstream_id: workstream_id, now: now)
      payload = {
        "base_message" => base_message.to_s,
        "gap" => gap.is_a?(Hash) ? gap : {}
      }

      with_db do |db|
        ensure_workstream_exists!(db, workstream_id: workstream_id)
        tx_started = false
        db.transaction
        tx_started = true
        close_open_for_chat!(db, chat_id: chat_id)
        db.execute(
          "INSERT INTO clarification_sessions (id, chat_id, workstream_id, status, gap_type, payload_json, resolved_fields_json, last_question_id, turn_counter, created_at, updated_at) VALUES (?, ?, ?, 'open', ?, ?, ?, ?, 0, ?, ?)",
          [session_id, chat_id, workstream_id, "planner_gap", JSON.generate(payload), JSON.generate({}), question_id, now, now]
        )
        db.commit
        Trace.sqlite(op: "insert", table: "clarification_sessions", detail: "id=#{session_id} status=open")
      rescue StandardError
        db.rollback if tx_started
        raise
      end

      get_open(chat_id: chat_id, workstream_id: workstream_id)
    end

    def open_control_stop(chat_id:, workstream_id:, reason:, accepted_partial: true, terminal_reason: "skill_stop_and_apply")
      now = utc_now
      session_id = build_id(chat_id: chat_id, workstream_id: workstream_id, now: now)
      payload = {
        "reason" => reason.to_s,
        "accepted_partial" => accepted_partial == true,
        "terminal_reason" => terminal_reason.to_s
      }

      with_db do |db|
        ensure_workstream_exists!(db, workstream_id: workstream_id)
        tx_started = false
        db.transaction
        tx_started = true
        close_open_for_chat!(db, chat_id: chat_id)
        db.execute(
          "INSERT INTO clarification_sessions (id, chat_id, workstream_id, status, gap_type, payload_json, resolved_fields_json, last_question_id, turn_counter, created_at, updated_at) VALUES (?, ?, ?, 'open', ?, ?, ?, ?, 0, ?, ?)",
          [session_id, chat_id, workstream_id, "control_stop", JSON.generate(payload), JSON.generate({}), nil, now, now]
        )
        db.commit
        Trace.sqlite(op: "insert", table: "clarification_sessions", detail: "id=#{session_id} status=open gap_type=control_stop")
      rescue StandardError
        db.rollback if tx_started
        raise
      end

      get_open(chat_id: chat_id, workstream_id: workstream_id)
    end

    def advance(chat_id:, session_id:, resolved_fields:, status:, last_question_id: nil)
      raise ArgumentError, "invalid status" unless STATUSES.include?(status)

      now = utc_now
      with_db do |db|
        row = db.get_first_row(
          "SELECT turn_counter, resolved_fields_json FROM clarification_sessions WHERE id = ? AND chat_id = ?",
          [session_id, chat_id]
        )
        raise ArgumentError, "clarification session not found" unless row

        turn_counter = row[0].to_i + 1
        current_resolved = parse_json_object(row[1])
        merged_resolved = current_resolved.merge(stringify_keys(resolved_fields))

        db.execute(
          "UPDATE clarification_sessions SET status = ?, resolved_fields_json = ?, last_question_id = ?, turn_counter = ?, updated_at = ? WHERE id = ?",
          [status, JSON.generate(merged_resolved), last_question_id, turn_counter, now, session_id]
        )
        Trace.sqlite(op: "update", table: "clarification_sessions", detail: "id=#{session_id} status=#{status}")
      end

      find_by_id(session_id)
    end

    def cancel_open(chat_id:, workstream_id: nil)
      update_open_status(chat_id: chat_id, workstream_id: workstream_id, status: "cancelled")
    end

    def timeout_open(chat_id:, workstream_id: nil)
      update_open_status(chat_id: chat_id, workstream_id: workstream_id, status: "timed_out")
    end

    private

    def update_open_status(chat_id:, workstream_id:, status:)
      now = utc_now
      with_db do |db|
        query = "UPDATE clarification_sessions SET status = ?, updated_at = ? WHERE chat_id = ? AND status = 'open'"
        args = [status, now, chat_id]
        unless workstream_id.nil?
          query += " AND workstream_id = ?"
          args << workstream_id
        end
        db.execute(query, args)
        Trace.sqlite(op: "update", table: "clarification_sessions", detail: "chat_id=#{chat_id} status=#{status}")
      end
    end

    def close_open_for_chat!(db, chat_id:)
      now = utc_now
      db.execute(
        "UPDATE clarification_sessions SET status = 'closed', updated_at = ? WHERE chat_id = ? AND status = 'open'",
        [now, chat_id]
      )
    end

    def find_by_id(id)
      with_db do |db|
        row = db.get_first_row(
          "SELECT id, chat_id, workstream_id, status, gap_type, payload_json, resolved_fields_json, last_question_id, turn_counter, created_at, updated_at FROM clarification_sessions WHERE id = ?",
          [id]
        )
        row_to_record(row)
      end
    end

    def row_to_record(row)
      return nil unless row

      ClarificationSessionRecord.new(
        id: row[0],
        chat_id: row[1],
        workstream_id: row[2],
        status: row[3],
        gap_type: row[4],
        payload: parse_json_object(row[5]),
        resolved_fields: parse_json_object(row[6]),
        last_question_id: row[7],
        turn_counter: row[8],
        created_at: row[9],
        updated_at: row[10]
      )
    end

    def parse_json_object(raw)
      parsed = JSON.parse(raw.to_s)
      parsed.is_a?(Hash) ? parsed : {}
    rescue JSON::ParserError
      {}
    end

    def stringify_keys(hash)
      return {} unless hash.is_a?(Hash)

      hash.each_with_object({}) { |(k, v), acc| acc[k.to_s] = v }
    end

    def with_db
      db = SQLite3::Database.new(@db_path)
      db.results_as_hash = false
      db.execute("PRAGMA foreign_keys = ON")
      yield db
    ensure
      db&.close
    end

    def build_id(chat_id:, workstream_id:, now:)
      suffix = Digest::SHA256.hexdigest("#{chat_id}:#{workstream_id}:#{now}")[0, 8]
      "cls-#{suffix}"
    end

    def ensure_workstream_exists!(db, workstream_id:)
      return if workstream_id.nil? || workstream_id.to_s.strip.empty?

      exists = db.get_first_value("SELECT 1 FROM workstreams WHERE id = ? LIMIT 1", [workstream_id]).to_i == 1
      return if exists

      raise PersistenceContractError, "invalid_workstream_reference: #{workstream_id}"
    end

    def utc_now
      Time.now.utc.iso8601(6)
    end
  end
end
