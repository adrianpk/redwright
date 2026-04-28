# frozen_string_literal: true

require "sqlite3"
require "digest"
require "time"

module Redwright
  class PsamStore
    def initialize(db_path)
      @db_path = db_path
    end

    def create_question(workstream_id:, step_index:, question:, recommendation: nil, rationale: nil, decision_node: nil, completion_status: nil)
      now = utc_now
      id = psam_id("alq", "#{workstream_id}:#{step_index}:#{question}")
      with_db do |db|
        db.execute(
          <<~SQL,
            INSERT INTO alignment_questions (
              id, workstream_id, step_index, question, recommendation, rationale, decision_node, completion_status, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          SQL
          [id, workstream_id, step_index, question, recommendation, rationale, decision_node, completion_status, now]
        )
      end
      id
    end

    def create_answer(question_id:, answer:)
      now = utc_now
      id = psam_id("ala", "#{question_id}:#{answer}")
      with_db do |db|
        db.execute(
          "INSERT INTO alignment_answers (id, question_id, answer, created_at) VALUES (?, ?, ?, ?)",
          [id, question_id, answer, now]
        )
      end
      id
    end

    def add_tag(question_id:, tag:)
      with_db do |db|
        db.execute(
          "INSERT INTO alignment_question_tags (question_id, tag, created_at) VALUES (?, ?, ?)",
          [question_id, tag, utc_now]
        )
      end
    end

    def add_dependency(question_id:, depends_on_question_id:)
      with_db do |db|
        db.execute(
          "INSERT INTO alignment_question_dependencies (question_id, depends_on_question_id, created_at) VALUES (?, ?, ?)",
          [question_id, depends_on_question_id, utc_now]
        )
      end
    end

    def add_artifact_link(workstream_id:, artifact_kind:, artifact_path:, task_id: nil, question_id: nil)
      id = psam_id("alaf", "#{workstream_id}:#{artifact_kind}:#{artifact_path}")
      with_db do |db|
        db.execute(
          <<~SQL,
            INSERT INTO alignment_artifact_links (id, workstream_id, task_id, question_id, artifact_kind, artifact_path, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
          SQL
          [id, workstream_id, task_id, question_id, artifact_kind, artifact_path, utc_now]
        )
      end
      id
    end

    def find_question(workstream_id:, step_index:)
      with_db do |db|
        row = db.get_first_row(
          "SELECT id, workstream_id, step_index, question FROM alignment_questions WHERE workstream_id = ? AND step_index = ?",
          [workstream_id, step_index]
        )
        next nil unless row

        { id: row[0], workstream_id: row[1], step_index: row[2], question: row[3] }
      end
    end

    def answer_exists?(question_id:)
      with_db do |db|
        row = db.get_first_row("SELECT 1 FROM alignment_answers WHERE question_id = ? LIMIT 1", [question_id])
        !row.nil?
      end
    end

    def list_semantic_context(project_id:, workstream_id: nil, tag: nil, limit: 25)
      with_db do |db|
        sql = <<~SQL
          SELECT
            q.id,
            q.workstream_id,
            q.step_index,
            q.question,
            q.recommendation,
            q.rationale,
            q.decision_node,
            q.completion_status,
            a.answer,
            GROUP_CONCAT(DISTINCT qt.tag) AS tags
          FROM alignment_questions q
          JOIN workstreams w ON w.id = q.workstream_id
          LEFT JOIN alignment_answers a ON a.question_id = q.id
          LEFT JOIN alignment_question_tags qt ON qt.question_id = q.id
          WHERE w.project_id = ?
        SQL
        binds = [project_id]
        if workstream_id
          sql += " AND q.workstream_id = ?"
          binds << workstream_id
        end
        if tag
          sql += " AND EXISTS (SELECT 1 FROM alignment_question_tags t WHERE t.question_id = q.id AND t.tag = ?)"
          binds << tag
        end
        sql += <<~SQL
          GROUP BY q.id
          ORDER BY q.created_at ASC
          LIMIT ?
        SQL
        binds << limit.to_i

        db.execute(sql, binds).map do |row|
          {
            id: row[0],
            workstream_id: row[1],
            step_index: row[2],
            question: row[3],
            recommendation: row[4],
            rationale: row[5],
            decision_node: row[6],
            completion_status: row[7],
            answer: row[8],
            tags: row[9].to_s.split(",").reject(&:empty?).sort
          }
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

    def psam_id(prefix, payload)
      "#{prefix}-#{Digest::SHA256.hexdigest(payload)[0, 10]}"
    end

    def utc_now
      Time.now.utc.iso8601(6)
    end
  end
end
