# frozen_string_literal: true

require "sqlite3"
require "digest"
require "time"

module Redwright
  AlignmentRecord = Struct.new(
    :workstream_id,
    :status,
    :step_index,
    :pending_question,
    :unresolved_count,
    :decisions_stable,
    :updated_at,
    keyword_init: true
  )

  class AlignmentStore
    QUESTIONS = [
      "What are the primary use cases this plan must cover?",
      "What inputs, outputs, and failure scenarios must be handled?",
      "What architecture components and data flow should implement this plan?"
    ].freeze

    def initialize(db_path)
      @db_path = db_path
    end

    def get(workstream_id)
      with_db do |db|
        row = db.get_first_row(
          "SELECT workstream_id, status, step_index, pending_question, unresolved_count, decisions_stable, updated_at FROM alignments WHERE workstream_id = ?",
          [workstream_id]
        )
        row ? row_to_record(row) : nil
      end
    end

    def ensure_session(workstream_id)
      now = utc_now
      with_db do |db|
        db.execute(
          <<~SQL,
            INSERT INTO alignments (workstream_id, status, step_index, pending_question, unresolved_count, decisions_stable, updated_at)
            VALUES (?, 'collecting_context', 0, NULL, ?, 0, ?)
            ON CONFLICT(workstream_id) DO NOTHING
          SQL
          [workstream_id, QUESTIONS.size, now]
        )
      end
      get(workstream_id)
    end

    def ask_next(workstream_id)
      session = ensure_session(workstream_id)
      return session if session.pending_question

      question = QUESTIONS[session.step_index]
      now = utc_now

      with_db do |db|
        db.execute(
          "UPDATE alignments SET pending_question = ?, updated_at = ? WHERE workstream_id = ?",
          [question, now, workstream_id]
        )
      end

      get(workstream_id)
    end

    def answer_pending(workstream_id, answer)
      session = ensure_session(workstream_id)
      raise ArgumentError, "no pending alignment question" unless session.pending_question

      now = utc_now
      next_index = session.step_index + 1
      unresolved = [QUESTIONS.size - next_index, 0].max
      done = next_index >= QUESTIONS.size
      pending = done ? nil : QUESTIONS[next_index]
      status = done ? "ready" : "collecting_context"
      stable = done ? 1 : 0

      with_db do |db|
        db.transaction

        db.execute(
          "INSERT INTO alignment_turns (id, workstream_id, step_index, question, answer, created_at) VALUES (?, ?, ?, ?, ?, ?)",
          [turn_id(workstream_id, session.step_index, now), workstream_id, session.step_index, session.pending_question, answer, now]
        )

        db.execute(
          "UPDATE alignments SET status = ?, step_index = ?, pending_question = ?, unresolved_count = ?, decisions_stable = ?, updated_at = ? WHERE workstream_id = ?",
          [status, next_index, pending, unresolved, stable, now, workstream_id]
        )

        db.commit
      rescue StandardError
        db.rollback
        raise
      end

      get(workstream_id)
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

    def row_to_record(r)
      AlignmentRecord.new(
        workstream_id: r[0],
        status: r[1],
        step_index: r[2],
        pending_question: r[3],
        unresolved_count: r[4],
        decisions_stable: r[5] == 1,
        updated_at: r[6]
      )
    end

    def turn_id(workstream_id, step_index, now)
      "aln-#{Digest::SHA256.hexdigest("#{workstream_id}:#{step_index}:#{now}")[0, 10]}"
    end

    def utc_now
      Time.now.utc.iso8601(6)
    end
  end
end
