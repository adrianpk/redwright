# frozen_string_literal: true

require "tmpdir"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/chat_context_store"
require "redwright/telegram_context_resolver"

class TelegramContextResolverTest < Minitest::Test
  def test_resolve_prefers_explicit_reference_match
    Dir.mktmpdir("redwright-context-resolver-explicit-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        contexts = Redwright::ChatContextStore.new(bootstrap.db_path)
        resolver = Redwright::TelegramContextResolver.new(project_store: projects, chat_context_store: contexts)

        first = projects.register(path: "#{dir}/apps/alpha", aliases: ["rw-alpha"])
        _second = projects.register(path: "#{dir}/apps/beta", aliases: ["rw-beta"])

        result = resolver.resolve(chat_id: 99, text: "project:rw-alpha update docs")
        assert_equal(true, result.resolved)
        assert_equal(first.id, result.project_ref)
      end
    end
  end

  def test_resolve_falls_back_to_chat_context
    Dir.mktmpdir("redwright-context-resolver-chat-fallback-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        contexts = Redwright::ChatContextStore.new(bootstrap.db_path)
        resolver = Redwright::TelegramContextResolver.new(project_store: projects, chat_context_store: contexts)

        project = projects.register(path: "#{dir}/apps/core", aliases: ["rw"])
        contexts.upsert(chat_id: 42, project_id: project.id, workstream_id: "ws-1")

        result = resolver.resolve(chat_id: 42, text: "continue with next step")
        assert_equal(true, result.resolved)
        assert_equal(project.id, result.project_ref)
        assert_equal("ws-1", result.workstream_id)
      end
    end
  end

  def test_resolve_returns_clarify_when_explicit_matches_are_ambiguous
    Dir.mktmpdir("redwright-context-resolver-ambiguous-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        contexts = Redwright::ChatContextStore.new(bootstrap.db_path)
        resolver = Redwright::TelegramContextResolver.new(project_store: projects, chat_context_store: contexts)

        projects.register(path: "#{dir}/apps/alpha", aliases: ["rw-alpha"])
        projects.register(path: "#{dir}/apps/beta", aliases: ["rw-beta"])

        result = resolver.resolve(chat_id: 7, text: "work on rw-alpha and rw-beta")
        assert_equal(false, result.resolved)
        assert_match("multiple project matches", result.question)
      end
    end
  end
end
