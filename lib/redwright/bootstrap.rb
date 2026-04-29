# frozen_string_literal: true

require "fileutils"
require "sqlite3"
require_relative "paths"
require_relative "alignment_persistence_hygiene"
require_relative "clarification_persistence_hygiene"

module Redwright
  BootstrapResult = Struct.new(:state_dir, :config_dir, :projects_root, :worktrees_root, :db_path, keyword_init: true)

  class Bootstrap
    def initialize(mode: :dev)
      @mode = mode
    end

    def call
      paths = Paths.new(mode: @mode)

      FileUtils.mkdir_p(paths.state_dir)
      FileUtils.mkdir_p(paths.config_dir)
      FileUtils.mkdir_p(paths.projects_root)
      FileUtils.mkdir_p(paths.worktrees_root)

      init_db(paths.db_path)
      AlignmentPersistenceHygiene.new(paths.db_path).run!
      ClarificationPersistenceHygiene.new(paths.db_path).run!

      BootstrapResult.new(
        state_dir: paths.state_dir,
        config_dir: paths.config_dir,
        projects_root: paths.projects_root,
        worktrees_root: paths.worktrees_root,
        db_path: paths.db_path
      )
    end

    private

    def init_db(db_path)
      db = SQLite3::Database.new(db_path)
      db.execute_batch(<<~SQL)
        PRAGMA journal_mode = WAL;
        PRAGMA foreign_keys = ON;

        CREATE TABLE IF NOT EXISTS runtime_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS projects (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          path TEXT NOT NULL UNIQUE,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          last_active_at TEXT
        );

        CREATE TABLE IF NOT EXISTS project_aliases (
          alias TEXT PRIMARY KEY,
          project_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS workstreams (
          id TEXT PRIMARY KEY,
          project_id TEXT NOT NULL,
          intent TEXT NOT NULL,
          state TEXT NOT NULL,
          branch TEXT,
          worktree_path TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS tasks (
          id TEXT PRIMARY KEY,
          workstream_id TEXT NOT NULL,
          trace_id TEXT,
          description TEXT NOT NULL,
          status TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY(workstream_id) REFERENCES workstreams(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS task_commits (
          task_id TEXT NOT NULL,
          commit_sha TEXT NOT NULL,
          created_at TEXT NOT NULL,
          PRIMARY KEY(task_id, commit_sha),
          FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS alignments (
          workstream_id TEXT PRIMARY KEY,
          status TEXT NOT NULL,
          step_index INTEGER NOT NULL,
          pending_question TEXT,
          unresolved_count INTEGER NOT NULL,
          decisions_stable INTEGER NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY(workstream_id) REFERENCES workstreams(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS alignment_turns (
          id TEXT PRIMARY KEY,
          workstream_id TEXT NOT NULL,
          step_index INTEGER NOT NULL,
          question TEXT NOT NULL,
          answer TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY(workstream_id) REFERENCES workstreams(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS alignment_questions (
          id TEXT PRIMARY KEY,
          workstream_id TEXT NOT NULL,
          step_index INTEGER NOT NULL,
          question TEXT NOT NULL,
          recommendation TEXT,
          rationale TEXT,
          decision_node TEXT,
          completion_status TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY(workstream_id) REFERENCES workstreams(id) ON DELETE CASCADE,
          UNIQUE(workstream_id, step_index)
        );

        CREATE TABLE IF NOT EXISTS alignment_answers (
          id TEXT PRIMARY KEY,
          question_id TEXT NOT NULL UNIQUE,
          answer TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY(question_id) REFERENCES alignment_questions(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS alignment_question_tags (
          question_id TEXT NOT NULL,
          tag TEXT NOT NULL,
          created_at TEXT NOT NULL,
          PRIMARY KEY(question_id, tag),
          FOREIGN KEY(question_id) REFERENCES alignment_questions(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS alignment_question_dependencies (
          question_id TEXT NOT NULL,
          depends_on_question_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          PRIMARY KEY(question_id, depends_on_question_id),
          FOREIGN KEY(question_id) REFERENCES alignment_questions(id) ON DELETE CASCADE,
          FOREIGN KEY(depends_on_question_id) REFERENCES alignment_questions(id) ON DELETE CASCADE,
          CHECK(question_id != depends_on_question_id)
        );

        CREATE TABLE IF NOT EXISTS alignment_artifact_links (
          id TEXT PRIMARY KEY,
          workstream_id TEXT NOT NULL,
          task_id TEXT,
          question_id TEXT,
          artifact_kind TEXT NOT NULL,
          artifact_path TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY(workstream_id) REFERENCES workstreams(id) ON DELETE CASCADE,
          FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE SET NULL,
          FOREIGN KEY(question_id) REFERENCES alignment_questions(id) ON DELETE SET NULL
        );

        CREATE INDEX IF NOT EXISTS idx_alignment_questions_workstream_step
          ON alignment_questions(workstream_id, step_index);
        CREATE INDEX IF NOT EXISTS idx_alignment_answers_question
          ON alignment_answers(question_id);
        CREATE INDEX IF NOT EXISTS idx_alignment_tags_tag
          ON alignment_question_tags(tag);
        CREATE INDEX IF NOT EXISTS idx_alignment_dependencies_question
          ON alignment_question_dependencies(question_id);
        CREATE INDEX IF NOT EXISTS idx_alignment_artifacts_workstream
          ON alignment_artifact_links(workstream_id);

        CREATE TABLE IF NOT EXISTS alignment_interruptions (
          workstream_id TEXT PRIMARY KEY,
          interruption_type TEXT NOT NULL,
          reason TEXT NOT NULL,
          previous_state TEXT NOT NULL,
          open_question_count INTEGER NOT NULL,
          risk_acknowledged INTEGER NOT NULL,
          open_branch_snapshot TEXT,
          created_at TEXT NOT NULL,
          resumed_at TEXT,
          FOREIGN KEY(workstream_id) REFERENCES workstreams(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS chat_contexts (
          chat_id INTEGER PRIMARY KEY,
          project_id TEXT NOT NULL,
          workstream_id TEXT,
          updated_at TEXT NOT NULL,
          FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS clarification_sessions (
          id TEXT PRIMARY KEY,
          chat_id INTEGER NOT NULL,
          workstream_id TEXT,
          status TEXT NOT NULL,
          gap_type TEXT NOT NULL,
          payload_json TEXT NOT NULL,
          resolved_fields_json TEXT NOT NULL,
          last_question_id TEXT,
          turn_counter INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_clarification_sessions_chat_status
          ON clarification_sessions(chat_id, status, updated_at DESC);
        CREATE INDEX IF NOT EXISTS idx_clarification_sessions_workstream_status
          ON clarification_sessions(workstream_id, status, updated_at DESC);

        CREATE TABLE IF NOT EXISTS action_executions (
          id TEXT PRIMARY KEY,
          task_id TEXT NOT NULL,
          trace_id TEXT,
          action_id TEXT NOT NULL,
          action_type TEXT NOT NULL,
          status TEXT NOT NULL,
          stdout TEXT,
          stderr TEXT,
          error_message TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS planner_rejections (
          id TEXT PRIMARY KEY,
          trace_id TEXT,
          project_id TEXT,
          project_ref TEXT,
          reason TEXT NOT NULL,
          raw_output TEXT,
          user_text TEXT,
          created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS execution_feedbacks (
          id TEXT PRIMARY KEY,
          trace_id TEXT,
          workstream_id TEXT,
          task_id TEXT,
          attempt INTEGER NOT NULL,
          failure_class TEXT NOT NULL,
          fingerprint TEXT NOT NULL,
          details_json TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY(workstream_id) REFERENCES workstreams(id) ON DELETE CASCADE,
          FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE
        );

        UPDATE runtime_metadata
        SET value = '10', updated_at = datetime('now')
        WHERE key = 'schema_version';

        INSERT INTO runtime_metadata (key, value, updated_at)
        SELECT 'schema_version', '10', datetime('now')
        WHERE NOT EXISTS (
          SELECT 1 FROM runtime_metadata WHERE key = 'schema_version'
        );
      SQL

      ensure_column(db, table: "tasks", column: "trace_id", column_sql: "TEXT")
      ensure_column(db, table: "action_executions", column: "trace_id", column_sql: "TEXT")
    ensure
      db&.close
    end

    def ensure_column(db, table:, column:, column_sql:)
      return if column_exists?(db, table: table, column: column)

      db.execute("ALTER TABLE #{table} ADD COLUMN #{column} #{column_sql}")
    end

    def column_exists?(db, table:, column:)
      rows = db.execute("PRAGMA table_info(#{table})")
      rows.any? { |row| row[1] == column }
    end
  end
end
