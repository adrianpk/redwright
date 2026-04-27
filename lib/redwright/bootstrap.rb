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

        CREATE TABLE IF NOT EXISTS runtime_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );

        INSERT INTO runtime_metadata (key, value, updated_at)
        VALUES ('schema_version', '1', datetime('now'))
        ON CONFLICT(key) DO UPDATE SET
          value = excluded.value,
          updated_at = excluded.updated_at;
      SQL
    ensure
      db&.close
    end
  end
end
