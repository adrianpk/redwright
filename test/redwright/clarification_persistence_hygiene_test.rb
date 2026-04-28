# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"
require "sqlite3"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/clarification_persistence_hygiene"
require "redwright/clarification_session_store"

class ClarificationPersistenceHygieneTest < Minitest::Test
  def test_timeouts_stale_open_clarification_sessions
    Dir.mktmpdir("redwright-clarification-hygiene-timeout-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        db = SQLite3::Database.new(bootstrap.db_path)
        db.results_as_hash = false

        db.execute(
          "INSERT INTO clarification_sessions (id, chat_id, workstream_id, status, gap_type, payload_json, resolved_fields_json, last_question_id, turn_counter, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
          ["cls-old", 42, nil, "open", "planner_gap", "{}", "{}", nil, 0, "2000-01-01 00:00:00", "2000-01-01 00:00:00"]
        )

        Redwright::ClarificationPersistenceHygiene.new(bootstrap.db_path, session_ttl_seconds: 60).run!
        status = db.get_first_value("SELECT status FROM clarification_sessions WHERE id = 'cls-old'")
        assert_equal("timed_out", status)
      ensure
        db&.close
      end
    end
  end

  def test_cancels_open_sessions_with_missing_workstream
    Dir.mktmpdir("redwright-clarification-hygiene-orphan-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        db = SQLite3::Database.new(bootstrap.db_path)
        db.results_as_hash = false

        db.execute(
          "INSERT INTO clarification_sessions (id, chat_id, workstream_id, status, gap_type, payload_json, resolved_fields_json, last_question_id, turn_counter, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
          ["cls-orphan", 43, "ws-missing", "open", "planner_gap", "{}", "{}", nil, 0, "2026-01-01 00:00:00", "2026-01-01 00:00:00"]
        )

        Redwright::ClarificationPersistenceHygiene.new(bootstrap.db_path, session_ttl_seconds: 60 * 60 * 24 * 365).run!
        status = db.get_first_value("SELECT status FROM clarification_sessions WHERE id = 'cls-orphan'")
        assert_equal("cancelled", status)
      ensure
        db&.close
      end
    end
  end

  def test_repairs_broken_chat_context_workstream_linkage
    Dir.mktmpdir("redwright-clarification-hygiene-chat-context-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        db = SQLite3::Database.new(bootstrap.db_path)
        db.results_as_hash = false

        db.execute(
          "INSERT INTO projects (id, name, path, created_at, updated_at, last_active_at) VALUES (?, ?, ?, datetime('now'), datetime('now'), NULL)",
          ["project-a", "project-a", "/tmp/project-a"]
        )
        db.execute(
          "INSERT INTO projects (id, name, path, created_at, updated_at, last_active_at) VALUES (?, ?, ?, datetime('now'), datetime('now'), NULL)",
          ["project-b", "project-b", "/tmp/project-b"]
        )
        db.execute(
          "INSERT INTO workstreams (id, project_id, intent, state, branch, worktree_path, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))",
          ["ws-b", "project-b", "change", "executing", nil, nil]
        )
        db.execute(
          "INSERT INTO chat_contexts (chat_id, project_id, workstream_id, updated_at) VALUES (?, ?, ?, datetime('now'))",
          [88, "project-a", "ws-b"]
        )

        Redwright::ClarificationPersistenceHygiene.new(bootstrap.db_path).run!
        repaired = db.get_first_value("SELECT workstream_id FROM chat_contexts WHERE chat_id = 88")
        assert_nil(repaired)
      ensure
        db&.close
      end
    end
  end

  def test_restart_recovery_preserves_recent_open_session
    Dir.mktmpdir("redwright-clarification-hygiene-restart-") do |dir|
      Dir.chdir(dir) do
        first = Redwright::Bootstrap.new(mode: :dev).call
        store = Redwright::ClarificationSessionStore.new(first.db_path)
        opened = store.open_project_name_confirm(
          chat_id: 99,
          workstream_id: nil,
          suggested_project_name: "guess-number",
          question_id: "project_name_confirm"
        )
        assert_equal("open", opened.status)

        second = Redwright::Bootstrap.new(mode: :dev).call
        restarted_store = Redwright::ClarificationSessionStore.new(second.db_path)
        recovered = restarted_store.get_open(chat_id: 99)
        refute_nil(recovered)
        assert_equal(opened.id, recovered.id)
        assert_equal("open", recovered.status)
      end
    end
  end
end
