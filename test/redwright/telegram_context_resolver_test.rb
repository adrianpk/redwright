# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/chat_context_store"
require "redwright/workstream_store"
require "redwright/clarification_session_store"
require "redwright/telegram_context_resolver"

class TelegramContextResolverTest < Minitest::Test
  def test_resolve_prefers_explicit_reference_match
    Dir.mktmpdir("redwright-context-resolver-explicit-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        contexts = Redwright::ChatContextStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        clarifications = Redwright::ClarificationSessionStore.new(bootstrap.db_path)
        resolver = Redwright::TelegramContextResolver.new(project_store: projects, chat_context_store: contexts, clarification_session_store: clarifications)

        first = projects.register(path: "#{dir}/apps/alpha", aliases: ["rw-alpha"])
        _second = projects.register(path: "#{dir}/apps/beta", aliases: ["rw-beta"])

        result = resolver.resolve(chat_id: 99, text: "project:rw-alpha update docs")
        assert_equal(true, result.resolved)
        assert_equal(first.id, result.project_ref)
        assert_equal(first.path, result.project_path)
      end
    end
  end

  def test_resolve_falls_back_to_chat_context
    Dir.mktmpdir("redwright-context-resolver-chat-fallback-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        contexts = Redwright::ChatContextStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        clarifications = Redwright::ClarificationSessionStore.new(bootstrap.db_path)
        resolver = Redwright::TelegramContextResolver.new(project_store: projects, chat_context_store: contexts, clarification_session_store: clarifications)

        project = projects.register(path: "#{dir}/apps/core", aliases: ["rw"])
        workstream = workstreams.create(project_id: project.id, intent: "change", state: "executing")
        contexts.upsert(chat_id: 42, project_id: project.id, workstream_id: workstream.id)

        result = resolver.resolve(chat_id: 42, text: "continue with next step")
        assert_equal(true, result.resolved)
        assert_equal(project.id, result.project_ref)
        assert_equal(project.path, result.project_path)
        assert_equal(workstream.id, result.workstream_id)
      end
    end
  end

  def test_resolve_returns_clarify_when_explicit_matches_are_ambiguous
    Dir.mktmpdir("redwright-context-resolver-ambiguous-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        contexts = Redwright::ChatContextStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        clarifications = Redwright::ClarificationSessionStore.new(bootstrap.db_path)
        resolver = Redwright::TelegramContextResolver.new(project_store: projects, chat_context_store: contexts, clarification_session_store: clarifications)

        projects.register(path: "#{dir}/apps/alpha", aliases: ["rw-alpha"])
        projects.register(path: "#{dir}/apps/beta", aliases: ["rw-beta"])

        result = resolver.resolve(chat_id: 7, text: "work on rw-alpha and rw-beta")
        assert_equal(false, result.resolved)
        assert_match("multiple project matches", result.question)
      end
    end
  end

  def test_resolve_bootstraps_first_run_from_single_workspace_project
    Dir.mktmpdir("redwright-context-resolver-bootstrap-single-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        contexts = Redwright::ChatContextStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        clarifications = Redwright::ClarificationSessionStore.new(bootstrap.db_path)
        FileUtils.mkdir_p(File.join(bootstrap.projects_root, "hello-cli"))
        resolver = Redwright::TelegramContextResolver.new(
          project_store: projects,
          chat_context_store: contexts,
          projects_root: bootstrap.projects_root,
          clarification_session_store: clarifications
        )

        result = resolver.resolve(chat_id: 123, text: "create something")
        assert_equal(true, result.resolved)
        assert_equal(File.join(bootstrap.projects_root, "hello-cli"), result.project_path)
        assert_equal(1, projects.list.size)

        context = contexts.get(123)
        refute_nil(context)
        assert_equal(result.project_ref, context.project_id)
      end
    end
  end

  def test_resolve_bootstraps_first_run_by_creating_default_project_when_workspace_is_empty
    Dir.mktmpdir("redwright-context-resolver-bootstrap-empty-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        contexts = Redwright::ChatContextStore.new(bootstrap.db_path)
        clarifications = Redwright::ClarificationSessionStore.new(bootstrap.db_path)
        resolver = Redwright::TelegramContextResolver.new(
          project_store: projects,
          chat_context_store: contexts,
          projects_root: bootstrap.projects_root,
          clarification_session_store: clarifications
        )

        result = resolver.resolve(chat_id: 456, text: "start now")
        expected_path = File.join(bootstrap.projects_root, "project-1")
        assert_equal(true, result.resolved)
        assert_equal(expected_path, result.project_path)
        assert(File.directory?(expected_path))
        assert_equal(1, projects.list.size)

        context = contexts.get(456)
        refute_nil(context)
        assert_equal(result.project_ref, context.project_id)
      end
    end
  end

  def test_resolve_keeps_clarify_when_bootstrap_candidates_are_ambiguous
    Dir.mktmpdir("redwright-context-resolver-bootstrap-ambiguous-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        contexts = Redwright::ChatContextStore.new(bootstrap.db_path)
        clarifications = Redwright::ClarificationSessionStore.new(bootstrap.db_path)
        FileUtils.mkdir_p(File.join(bootstrap.projects_root, "alpha"))
        FileUtils.mkdir_p(File.join(bootstrap.projects_root, "beta"))
        resolver = Redwright::TelegramContextResolver.new(
          project_store: projects,
          chat_context_store: contexts,
          projects_root: bootstrap.projects_root,
          clarification_session_store: clarifications
        )

        result = resolver.resolve(chat_id: 777, text: "build feature")
        assert_equal(false, result.resolved)
        assert_match("No active project context found", result.question)
        assert_equal(0, projects.list.size)
        assert_nil(contexts.get(777))
      end
    end
  end

  def test_resolve_asks_for_inferred_project_name_confirmation_then_confirms
    Dir.mktmpdir("redwright-context-resolver-infer-confirm-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        contexts = Redwright::ChatContextStore.new(bootstrap.db_path)
        clarifications = Redwright::ClarificationSessionStore.new(bootstrap.db_path)
        resolver = Redwright::TelegramContextResolver.new(
          project_store: projects,
          chat_context_store: contexts,
          projects_root: bootstrap.projects_root,
          clarification_session_store: clarifications
        )

        first = resolver.resolve(chat_id: 200, text: "Create a tiny CLI project named hello-cli")
        assert_equal(false, first.resolved)
        assert_match("I inferred project name 'hello-cli'", first.question)

        second = resolver.resolve(chat_id: 200, text: "yes")
        assert_equal(true, second.resolved)
        assert_equal(File.join(bootstrap.projects_root, "hello-cli"), second.project_path)
      end
    end
  end

  def test_resolve_pending_inferred_project_accepts_replacement_name
    Dir.mktmpdir("redwright-context-resolver-infer-replace-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        contexts = Redwright::ChatContextStore.new(bootstrap.db_path)
        clarifications = Redwright::ClarificationSessionStore.new(bootstrap.db_path)
        resolver = Redwright::TelegramContextResolver.new(
          project_store: projects,
          chat_context_store: contexts,
          projects_root: bootstrap.projects_root,
          clarification_session_store: clarifications
        )

        first = resolver.resolve(chat_id: 300, text: "start project called sample-one")
        assert_equal(false, first.resolved)

        second = resolver.resolve(chat_id: 300, text: "better use sample-two and module example.com/sample-two")
        assert_equal(true, second.resolved)
        assert_equal(File.join(bootstrap.projects_root, "sample-two"), second.project_path)
      end
    end
  end

  def test_pending_clarification_survives_resolver_restart
    Dir.mktmpdir("redwright-context-resolver-restart-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        contexts = Redwright::ChatContextStore.new(bootstrap.db_path)
        clarifications = Redwright::ClarificationSessionStore.new(bootstrap.db_path)

        first_resolver = Redwright::TelegramContextResolver.new(
          project_store: projects,
          chat_context_store: contexts,
          projects_root: bootstrap.projects_root,
          clarification_session_store: clarifications
        )
        first = first_resolver.resolve(chat_id: 900, text: "create project named restart-sample")
        assert_equal(false, first.resolved)
        assert_match("inferred project name", first.question)

        second_resolver = Redwright::TelegramContextResolver.new(
          project_store: projects,
          chat_context_store: contexts,
          projects_root: bootstrap.projects_root,
          clarification_session_store: clarifications
        )
        second = second_resolver.resolve(chat_id: 900, text: "yes")
        assert_equal(true, second.resolved)
        assert_equal(File.join(bootstrap.projects_root, "restart-sample"), second.project_path)
      end
    end
  end

  def test_resolve_allows_explicit_cross_project_switch_when_session_has_active_project
    Dir.mktmpdir("redwright-context-resolver-session-continuity-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        contexts = Redwright::ChatContextStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        clarifications = Redwright::ClarificationSessionStore.new(bootstrap.db_path)
        resolver = Redwright::TelegramContextResolver.new(
          project_store: projects,
          chat_context_store: contexts,
          projects_root: bootstrap.projects_root,
          clarification_session_store: clarifications
        )

        alpha = projects.register(path: File.join(bootstrap.projects_root, "alpha"), aliases: ["alpha"])
        beta = projects.register(path: File.join(bootstrap.projects_root, "beta"), aliases: ["beta"])
        ws_alpha = workstreams.create(project_id: alpha.id, intent: "change", state: "executing")
        contexts.upsert(chat_id: 501, project_id: alpha.id, workstream_id: ws_alpha.id)

        result = resolver.resolve(chat_id: 501, text: "beta implement parser fix")
        assert_equal(true, result.resolved)
        assert_equal(beta.id, result.project_ref)
        assert_nil(result.workstream_id)
      end
    end
  end

  def test_resolve_allows_after_explicit_session_switch
    Dir.mktmpdir("redwright-context-resolver-session-switch-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        projects = Redwright::ProjectStore.new(bootstrap.db_path)
        contexts = Redwright::ChatContextStore.new(bootstrap.db_path)
        workstreams = Redwright::WorkstreamStore.new(bootstrap.db_path)
        clarifications = Redwright::ClarificationSessionStore.new(bootstrap.db_path)
        resolver = Redwright::TelegramContextResolver.new(
          project_store: projects,
          chat_context_store: contexts,
          projects_root: bootstrap.projects_root,
          clarification_session_store: clarifications
        )

        alpha = projects.register(path: File.join(bootstrap.projects_root, "alpha"), aliases: ["alpha"])
        beta = projects.register(path: File.join(bootstrap.projects_root, "beta"), aliases: ["beta"])
        ws_alpha = workstreams.create(project_id: alpha.id, intent: "change", state: "executing")
        contexts.upsert(chat_id: 502, project_id: alpha.id, workstream_id: ws_alpha.id)

        contexts.upsert(chat_id: 502, project_id: beta.id, workstream_id: nil)
        result = resolver.resolve(chat_id: 502, text: "beta implement parser fix")
        assert_equal(true, result.resolved)
        assert_equal(beta.id, result.project_ref)
      end
    end
  end
end
