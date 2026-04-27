# frozen_string_literal: true

require "fileutils"
require "sqlite3"
require_relative "paths"

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

        CREATE TABLE IF NOT EXISTS chat_contexts (
          chat_id INTEGER PRIMARY KEY,
          project_id TEXT NOT NULL,
          workstream_id TEXT,
          updated_at TEXT NOT NULL,
          FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
        );

        INSERT INTO runtime_metadata (key, value, updated_at)
        VALUES ('schema_version', '4', datetime('now'))
        ON CONFLICT(key) DO UPDATE SET
          value = excluded.value,
          updated_at = excluded.updated_at;
      SQL
    ensure
      db&.close
    end
  end
end
