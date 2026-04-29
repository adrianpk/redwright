# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/workstream_store"
require "redwright/task_store"
require "redwright/alignment_store"
require "redwright/alignment_interruption_store"
require "redwright/runtime_flow"
require "redwright/primitive_executor"
require "redwright/action_execution_store"
require "redwright/server_runtime_dispatcher"

class ServerRuntimeDispatcherTest < Minitest::Test
  def test_send_dispatch_executes_flow_and_persists_action_results
    Dir.mktmpdir("redwright-server-dispatcher-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        path = File.join(bootstrap.projects_root, "alpha")
        FileUtils.mkdir_p(path)
        project = project_store.register(path: path, aliases: ["alpha"])

        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: Redwright::WorkstreamStore.new(bootstrap.db_path),
          task_store: Redwright::TaskStore.new(bootstrap.db_path),
          alignment_store: Redwright::AlignmentStore.new(bootstrap.db_path),
          alignment_interruption_store: Redwright::AlignmentInterruptionStore.new(bootstrap.db_path),
          primitive_executor: Redwright::PrimitiveExecutor.new(
            allowed_projects_root: bootstrap.projects_root,
            enforce_mutating_projects_root: true
          ),
          action_execution_store: Redwright::ActionExecutionStore.new(bootstrap.db_path)
        )
        dispatcher = Redwright::ServerRuntimeDispatcher.new(flow: flow, blocked_retry_attempts: 1)

        response = dispatcher.call(
          "type" => "send",
          "session_id" => "s1",
          "payload" => {
            "channel" => "tui",
            "project_ref" => "alpha",
            "intent" => "change",
            "message" => "write hello file",
            "actions" => [
              {
                "id" => "a1",
                "type" => "write_file",
                "args" => { "path" => "README.md", "content" => "hello\n" },
                "requires_confirmation" => false,
                "timeout_ms" => 10_000,
                "on_failure" => "abort"
              }
            ]
          }
        )

        assert_equal("ok", response["status"])
        assert_equal(project.id, response["project_id"])
        assert_equal("executing", response["state"])
        assert_equal(1, response["action_results"].size)
        assert_equal("ok", response["action_results"].first["status"])
        assert_equal(true, File.file?(File.join(path, "README.md")))
      end
    end
  end

  def test_send_dispatch_returns_error_payload_instead_of_raising
    flow = Object.new
    flow.define_singleton_method(:process) do |**_kwargs|
      raise RuntimeError, "project not found"
    end
    dispatcher = Redwright::ServerRuntimeDispatcher.new(flow: flow, blocked_retry_attempts: 1)

    response = dispatcher.call(
      "type" => "send",
      "session_id" => "s1",
      "payload" => {
        "channel" => "telegram",
        "project_ref" => "missing",
        "intent" => "change",
        "message" => "do work",
        "actions" => []
      }
    )

    assert_equal("error", response["status"])
    assert_equal("project not found", response["message"])
    assert_equal("RuntimeError", response["error_class"])
  end

  def test_send_dispatch_creates_project_from_project_new_slash_command
    Dir.mktmpdir("redwright-server-dispatcher-project-new-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: Redwright::WorkstreamStore.new(bootstrap.db_path),
          task_store: Redwright::TaskStore.new(bootstrap.db_path),
          alignment_store: Redwright::AlignmentStore.new(bootstrap.db_path),
          alignment_interruption_store: Redwright::AlignmentInterruptionStore.new(bootstrap.db_path),
          primitive_executor: Redwright::PrimitiveExecutor.new(
            allowed_projects_root: bootstrap.projects_root,
            enforce_mutating_projects_root: true
          ),
          action_execution_store: Redwright::ActionExecutionStore.new(bootstrap.db_path)
        )
        dispatcher = Redwright::ServerRuntimeDispatcher.new(
          flow: flow,
          blocked_retry_attempts: 1,
          project_store: project_store,
          projects_root: bootstrap.projects_root
        )

        response = dispatcher.call(
          "type" => "send",
          "session_id" => "telegram-42",
          "payload" => {
            "channel" => "telegram",
            "project_ref" => "rw",
            "intent" => "change",
            "message" => "/project new happy-cli",
            "actions" => []
          }
        )

        assert_equal("ok", response["status"])
        project = project_store.resolve(response["project_id"])
        refute_nil(project)
        assert_equal("happy-cli", project.name)
        assert_equal(true, File.directory?(File.join(bootstrap.projects_root, "happy-cli")))
      end
    end
  end

  def test_send_dispatch_switches_project_and_reuses_session_project_context
    Dir.mktmpdir("redwright-server-dispatcher-project-switch-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        alpha_path = File.join(bootstrap.projects_root, "alpha")
        beta_path = File.join(bootstrap.projects_root, "beta")
        FileUtils.mkdir_p(alpha_path)
        FileUtils.mkdir_p(beta_path)
        alpha = project_store.register(path: alpha_path, aliases: ["alpha"])
        beta = project_store.register(path: beta_path, aliases: ["beta"])

        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: Redwright::WorkstreamStore.new(bootstrap.db_path),
          task_store: Redwright::TaskStore.new(bootstrap.db_path),
          alignment_store: Redwright::AlignmentStore.new(bootstrap.db_path),
          alignment_interruption_store: Redwright::AlignmentInterruptionStore.new(bootstrap.db_path),
          primitive_executor: Redwright::PrimitiveExecutor.new(
            allowed_projects_root: bootstrap.projects_root,
            enforce_mutating_projects_root: true
          ),
          action_execution_store: Redwright::ActionExecutionStore.new(bootstrap.db_path)
        )
        dispatcher = Redwright::ServerRuntimeDispatcher.new(
          flow: flow,
          blocked_retry_attempts: 1,
          project_store: project_store,
          projects_root: bootstrap.projects_root
        )

        switch_response = dispatcher.call(
          "type" => "send",
          "session_id" => "telegram-77",
          "payload" => {
            "channel" => "telegram",
            "project_ref" => "rw",
            "intent" => "change",
            "message" => "/project switch alpha",
            "actions" => []
          }
        )
        assert_equal("ok", switch_response["status"])
        assert_equal(alpha.id, switch_response["project_id"])

        # Unknown project_ref should fall back to the session-bound project.
        follow_up = dispatcher.call(
          "type" => "send",
          "session_id" => "telegram-77",
          "payload" => {
            "channel" => "telegram",
            "project_ref" => "non-existent",
            "intent" => "change",
            "message" => "continue implementation",
            "actions" => []
          }
        )
        assert_equal("ok", follow_up["status"])
        assert_equal(alpha.id, follow_up["project_id"])
        refute_equal(beta.id, follow_up["project_id"])
      end
    end
  end
end
