# frozen_string_literal: true

require "sqlite3"
require "digest"
require "time"

module Redwright
  WorkstreamRecord = Struct.new(
    :id,
    :project_id,
    :intent,
    :state,
    :branch,
    :worktree_path,
    :created_at,
    :updated_at,
    keyword_init: true
  )

  class WorkstreamStore
    def initialize(db_path)
      @db_path = db_path
    end

    def create(project_id:, intent:, state: "ready", branch: nil, worktree_path: nil)
      now = utc_now
      id = build_id(project_id, intent, now)

      with_db do |db|
        db.execute(
          <<~SQL,
            INSERT INTO workstreams (id, project_id, intent, state, branch, worktree_path, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          SQL
          [id, project_id, intent, state, branch, worktree_path, now, now]
        )
      end

      get(id)
    end

    def list(project_id: nil)
      with_db do |db|
        rows = if project_id
                 db.execute(
                   "SELECT id, project_id, intent, state, branch, worktree_path, created_at, updated_at FROM workstreams WHERE project_id = ? ORDER BY updated_at DESC, rowid DESC",
                   [project_id]
                 )
               else
                 db.execute(
                   "SELECT id, project_id, intent, state, branch, worktree_path, created_at, updated_at FROM workstreams ORDER BY updated_at DESC, rowid DESC"
                 )
               end

        rows.map { |r| row_to_record(r) }
      end
    end

    def get(id)
      with_db do |db|
        row = db.get_first_row(
          "SELECT id, project_id, intent, state, branch, worktree_path, created_at, updated_at FROM workstreams WHERE id = ?",
          [id]
        )
        row ? row_to_record(row) : nil
      end
    end

    def find_latest(project_id:, intent:, states: nil)
      with_db do |db|
        query = +"SELECT id, project_id, intent, state, branch, worktree_path, created_at, updated_at FROM workstreams WHERE project_id = ? AND intent = ?"
        args = [project_id, intent]

        if states && !states.empty?
          placeholders = (["?"] * states.size).join(",")
          query << " AND state IN (#{placeholders})"
          args.concat(states)
        end

        query << " ORDER BY updated_at DESC, rowid DESC LIMIT 1"
        row = db.get_first_row(query, args)
        row ? row_to_record(row) : nil
      end
    end

    def update_state(id, state)
      now = utc_now
      with_db do |db|
        db.execute("UPDATE workstreams SET state = ?, updated_at = ? WHERE id = ?", [state, now, id])
      end
      get(id)
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

    def build_id(project_id, intent, now)
      suffix = Digest::SHA256.hexdigest("#{project_id}:#{intent}:#{now}")[0, 6]
      "ws-#{suffix}"
    end

    def row_to_record(r)
      WorkstreamRecord.new(
        id: r[0],
        project_id: r[1],
        intent: r[2],
        state: r[3],
        branch: r[4],
        worktree_path: r[5],
        created_at: r[6],
        updated_at: r[7]
      )
    end

    def utc_now
      Time.now.utc.iso8601(6)
    end
  end
end
