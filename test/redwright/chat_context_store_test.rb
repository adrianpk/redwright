# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/chat_context_store"
require "redwright/workstream_store"

class ChatContextStoreTest < Minitest::Test
  def test_upsert_and_get
    Dir.mktmpdir("redwright-chat-context-store-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        context_store = Redwright::ChatContextStore.new(bootstrap.db_path)

        project = projects.register(path: "#{dir}/apps/core", aliases: ["rw"])
        workstream = workstreams.create(project_id: project.id, intent: "change", state: "executing")
        record = context_store.upsert(chat_id: 42, project_id: project.id, workstream_id: workstream.id)

        assert_equal(42, record.chat_id)
        assert_equal(project.id, record.project_id)
        assert_equal(workstream.id, record.workstream_id)
        assert(record.updated_at)
      end
    end
  end

  def test_upsert_rejects_unknown_project_reference
    Dir.mktmpdir("redwright-chat-context-store-invalid-project-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        context_store = Redwright::ChatContextStore.new(bootstrap.db_path)

        err = assert_raises(Redwright::PersistenceContractError) do
          context_store.upsert(chat_id: 42, project_id: "missing-project", workstream_id: nil)
        end
        assert_match("invalid_project_reference", err.message)
      end
    end
  end

  def test_upsert_rejects_cross_project_workstream_reference
    Dir.mktmpdir("redwright-chat-context-store-cross-project-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        context_store = Redwright::ChatContextStore.new(bootstrap.db_path)

        alpha = projects.register(path: "#{dir}/apps/alpha", aliases: ["alpha"])
        beta = projects.register(path: "#{dir}/apps/beta", aliases: ["beta"])
        ws_alpha = workstreams.create(project_id: alpha.id, intent: "change", state: "executing")

        err = assert_raises(Redwright::PersistenceContractError) do
          context_store.upsert(chat_id: 42, project_id: beta.id, workstream_id: ws_alpha.id)
        end
        assert_match("cross_project_workstream_reference", err.message)
      end
    end
  end
end
