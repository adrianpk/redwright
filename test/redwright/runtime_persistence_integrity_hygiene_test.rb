# frozen_string_literal: true

require "tmpdir"
require "sqlite3"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/workstream_store"
require "redwright/runtime_persistence_integrity_hygiene"

class RuntimePersistenceIntegrityHygieneTest < Minitest::Test
  def test_hygiene_nullifies_orphan_links_for_clarification_and_planner_rejections
    Dir.mktmpdir("redwright-runtime-persistence-hygiene-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)

        project = projects.register(path: "#{dir}/apps/core", aliases: ["rw"])
        workstreams.create(project_id: project.id, intent: "change", state: "executing")

        db = SQLite3::Database.new(bootstrap.db_path)
        db.results_as_hash = false
        db.execute("PRAGMA foreign_keys = OFF")

        db.execute(
          "INSERT INTO clarification_sessions (id, chat_id, workstream_id, status, gap_type, payload_json, resolved_fields_json, last_question_id, turn_counter, created_at, updated_at) VALUES (?, ?, ?, 'closed', 'planner_gap', ?, ?, ?, 0, datetime('now'), datetime('now'))",
          ["cls-1", 42, "ws-missing", "{}", "{}", "q1"]
        )
        db.execute(
          "INSERT INTO planner_rejections (id, trace_id, project_id, project_ref, reason, raw_output, user_text, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))",
          ["rej-1", "trc-1", "project-missing", "rw", "invalid_schema", "{}", "hello"]
        )
        db.execute(
          "INSERT INTO planner_rejections (id, trace_id, project_id, project_ref, reason, raw_output, user_text, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))",
          ["rej-2", "trc-2", project.id, "rw", "invalid_schema", "{}", "hello"]
        )
        db.execute("PRAGMA foreign_keys = ON")
        db.close

        Redwright::RuntimePersistenceIntegrityHygiene.new(bootstrap.db_path).run!

        db2 = SQLite3::Database.new(bootstrap.db_path)
        db2.results_as_hash = false
        row = db2.get_first_row("SELECT workstream_id FROM clarification_sessions WHERE id = ?", ["cls-1"])
        assert_nil(row[0])
        rej1 = db2.get_first_row("SELECT project_id FROM planner_rejections WHERE id = ?", ["rej-1"])
        rej2 = db2.get_first_row("SELECT project_id FROM planner_rejections WHERE id = ?", ["rej-2"])
        assert_nil(rej1[0])
        assert_equal(project.id, rej2[0])
        db2.close

      end
    end
  end
end
