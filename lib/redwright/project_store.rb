# frozen_string_literal: true

require "sqlite3"
require "digest"
require "time"

module Redwright
  ProjectRecord = Struct.new(:id, :name, :path, :aliases, :last_active_at, keyword_init: true)

  class ProjectStore
    def initialize(db_path)
      @db_path = db_path
    end

    def register(path:, aliases: [])
      normalized_path = File.expand_path(path)
      name = File.basename(normalized_path)
      project_id = build_project_id(name, normalized_path)
      now = utc_now

      with_db do |db|
        db.transaction

        row = db.get_first_row("SELECT id FROM projects WHERE path = ?", [normalized_path])
        if row
          project_id = row[0]
          db.execute(
            "UPDATE projects SET name = ?, updated_at = ?, last_active_at = ? WHERE id = ?",
            [name, now, now, project_id]
          )
        else
          db.execute(
            "INSERT INTO projects (id, name, path, created_at, updated_at, last_active_at) VALUES (?, ?, ?, ?, ?, ?)",
            [project_id, name, normalized_path, now, now, now]
          )
        end

        aliases.each do |a|
          db.execute(
            "INSERT INTO project_aliases (alias, project_id, created_at) VALUES (?, ?, ?) ON CONFLICT(alias) DO UPDATE SET project_id = excluded.project_id",
            [a, project_id, now]
          )
        end

        db.commit
      rescue StandardError
        db.rollback
        raise
      end

      resolve(project_id)
    end

    def resolve(reference = nil)
      with_db do |db|
        if reference.nil? || reference.strip.empty?
          row = db.get_first_row("SELECT id FROM projects ORDER BY last_active_at DESC, updated_at DESC, rowid DESC LIMIT 1")
          return nil unless row

          return resolve(row[0])
        end

        ref = reference.strip
        row = db.get_first_row("SELECT id, name, path, last_active_at FROM projects WHERE id = ? OR path = ?", [ref, File.expand_path(ref)])
        unless row
          row = db.get_first_row(
            "SELECT p.id, p.name, p.path, p.last_active_at FROM projects p JOIN project_aliases a ON a.project_id = p.id WHERE a.alias = ?",
            [ref]
          )
        end
        return nil unless row

        aliases = db.execute("SELECT alias FROM project_aliases WHERE project_id = ? ORDER BY alias", [row[0]]).map(&:first)
        ProjectRecord.new(id: row[0], name: row[1], path: row[2], aliases: aliases, last_active_at: row[3])
      end
    end

    def mark_active(project_id)
      now = utc_now
      with_db do |db|
        db.execute("UPDATE projects SET last_active_at = ?, updated_at = ? WHERE id = ?", [now, now, project_id])
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

    def build_project_id(name, path)
      slug = name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
      suffix = Digest::SHA256.hexdigest(path)[0, 6]
      "#{slug}-#{suffix}"
    end

    def utc_now
      Time.now.utc.iso8601(6)
    end
  end
end
