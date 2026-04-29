# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/clarification_session_store"
require "redwright/project_store"
require "redwright/workstream_store"

class ClarificationSessionStoreTest < Minitest::Test
  def test_open_replaces_previous_open_session_for_chat
    Dir.mktmpdir("redwright-clarification-store-open-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        store = Redwright::ClarificationSessionStore.new(bootstrap.db_path)
        project = Redwright::ProjectStore.new(bootstrap.db_path).register(path: "#{dir}/apps/core", aliases: ["rw"])
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        ws1 = workstreams.create(project_id: project.id, intent: "change", state: "executing")
        ws2 = workstreams.create(project_id: project.id, intent: "change", state: "executing")

        first = store.open_project_name_confirm(chat_id: 10, workstream_id: ws1.id, suggested_project_name: "alpha", question_id: "q1")
        assert_equal("open", first.status)

        second = store.open_project_name_confirm(chat_id: 10, workstream_id: ws2.id, suggested_project_name: "beta", question_id: "q2")
        assert_equal("open", second.status)
        assert_equal("beta", second.payload["suggested_project_name"])

        open = store.get_open(chat_id: 10)
        assert_equal(second.id, open.id)
      end
    end
  end

  def test_advance_closes_and_persists_resolved_fields
    Dir.mktmpdir("redwright-clarification-store-advance-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        store = Redwright::ClarificationSessionStore.new(bootstrap.db_path)
        project = Redwright::ProjectStore.new(bootstrap.db_path).register(path: "#{dir}/apps/core", aliases: ["rw"])
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        ws1 = workstreams.create(project_id: project.id, intent: "change", state: "executing")

        opened = store.open_project_name_confirm(chat_id: 11, workstream_id: ws1.id, suggested_project_name: "hello-cli", question_id: "q1")
        updated = store.advance(
          chat_id: 11,
          session_id: opened.id,
          resolved_fields: { project_name: "hello-cli" },
          status: "closed",
          last_question_id: "q1"
        )

        assert_equal("closed", updated.status)
        assert_equal("hello-cli", updated.resolved_fields["project_name"])
        assert_equal(1, updated.turn_counter)
        assert_nil(store.get_open(chat_id: 11))
      end
    end
  end

  def test_cancel_open_marks_session_cancelled
    Dir.mktmpdir("redwright-clarification-store-cancel-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        store = Redwright::ClarificationSessionStore.new(bootstrap.db_path)
        project = Redwright::ProjectStore.new(bootstrap.db_path).register(path: "#{dir}/apps/core", aliases: ["rw"])
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        ws1 = workstreams.create(project_id: project.id, intent: "change", state: "executing")

        store.open_project_name_confirm(chat_id: 12, workstream_id: ws1.id, suggested_project_name: "sample", question_id: "q1")
        store.cancel_open(chat_id: 12)

        assert_nil(store.get_open(chat_id: 12))
      end
    end
  end

  def test_open_project_name_confirm_rejects_unknown_workstream
    Dir.mktmpdir("redwright-clarification-store-invalid-workstream-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        store = Redwright::ClarificationSessionStore.new(bootstrap.db_path)

        err = assert_raises(Redwright::PersistenceContractError) do
          store.open_project_name_confirm(
            chat_id: 13,
            workstream_id: "ws-missing",
            suggested_project_name: "sample",
            question_id: "q1"
          )
        end
        assert_match("invalid_workstream_reference", err.message)
      end
    end
  end
end
