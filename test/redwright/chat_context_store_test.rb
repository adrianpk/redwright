# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/chat_context_store"

class ChatContextStoreTest < Minitest::Test
  def test_upsert_and_get
    Dir.mktmpdir("redwright-chat-context-store-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        context_store = Redwright::ChatContextStore.new(bootstrap.db_path)

        project = projects.register(path: "#{dir}/apps/core", aliases: ["rw"])
        record = context_store.upsert(chat_id: 42, project_id: project.id, workstream_id: "ws-1")

        assert_equal(42, record.chat_id)
        assert_equal(project.id, record.project_id)
        assert_equal("ws-1", record.workstream_id)
        assert(record.updated_at)
      end
    end
  end
end
