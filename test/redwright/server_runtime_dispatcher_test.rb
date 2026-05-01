# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "open3"
require "yaml"
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
          projects_root: bootstrap.projects_root,
          task_store: Redwright::TaskStore.new(bootstrap.db_path),
          action_execution_store: Redwright::ActionExecutionStore.new(bootstrap.db_path)
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
        assert_equal("local_new", project.source_type)
        assert_equal("", project.source_ref)
        assert_equal(true, File.directory?(File.join(bootstrap.projects_root, "happy-cli")))
        manifest_path = File.join(project.path, ".redwright", "manifest.yml")
        assert_equal(true, File.file?(manifest_path))
        manifest = YAML.safe_load(File.read(manifest_path))
        assert_equal(1, manifest["schema_version"])
        assert_equal(project.id, manifest.dig("project", "id"))
        assert_equal("happy-cli", manifest.dig("project", "name"))
        assert_equal("happy-cli", manifest.dig("project", "slug"))
        assert_equal("unknown", manifest.dig("project", "stack"))
        assert_equal("new", manifest.dig("project", "created_via"))
        refute_nil(manifest.dig("project", "created_at"))
      end
    end
  end

  def test_send_dispatch_project_new_without_name_does_not_create_project_or_directory
    Dir.mktmpdir("redwright-server-dispatcher-project-new-missing-name-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        flow = Object.new
        flow.define_singleton_method(:process) do |**_kwargs|
          raise "flow should not run without a resolved project"
        end
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
            "project_ref" => "",
            "intent" => "change",
            "message" => "/project new",
            "actions" => []
          }
        )

        assert_equal("error", response["status"])
        assert_equal("missing_project_ref", response["message"])
        assert_equal([], project_store.list)
        created_entries = Dir.children(bootstrap.projects_root).sort
        assert_equal([".worktrees"], created_entries)
      end
    end
  end

  def test_project_new_is_idempotent_and_does_not_overwrite_existing_manifest
    Dir.mktmpdir("redwright-server-dispatcher-project-new-idempotent-") do |dir|
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
          projects_root: bootstrap.projects_root,
          task_store: Redwright::TaskStore.new(bootstrap.db_path),
          action_execution_store: Redwright::ActionExecutionStore.new(bootstrap.db_path)
        )

        first = dispatcher.call(
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
        project = project_store.resolve(first["project_id"])
        manifest_path = File.join(project.path, ".redwright", "manifest.yml")
        original_manifest = File.read(manifest_path)

        custom_manifest = {
          "schema_version" => 1,
          "project" => {
            "id" => project.id,
            "name" => "happy-cli",
            "slug" => "happy-cli",
            "stack" => "ruby",
            "created_via" => "new",
            "created_at" => "2026-04-29T00:00:00Z"
          }
        }
        File.write(manifest_path, YAML.dump(custom_manifest))

        second = dispatcher.call(
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
        assert_equal("ok", second["status"])
        assert_equal(project.id, second["project_id"])
        manifest_after = YAML.safe_load(File.read(manifest_path))
        assert_equal("ruby", manifest_after.dig("project", "stack"))
        assert_equal("2026-04-29T00:00:00Z", manifest_after.dig("project", "created_at"))
        refute_equal("", original_manifest)
      end
    end
  end

  def test_send_dispatch_creates_project_from_explicit_operational_intent
    Dir.mktmpdir("redwright-server-dispatcher-project-new-operational-intent-") do |dir|
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
          projects_root: bootstrap.projects_root,
          task_store: Redwright::TaskStore.new(bootstrap.db_path),
          action_execution_store: Redwright::ActionExecutionStore.new(bootstrap.db_path)
        )

        response = dispatcher.call(
          "type" => "send",
          "session_id" => "telegram-42",
          "payload" => {
            "channel" => "telegram",
            "project_ref" => "rw",
            "intent" => "change",
            "message" => "Create a new project named obelix",
            "actions" => [],
            "operational_intent" => "project_new",
            "operational_args" => { "project_name" => "obelix" }
          }
        )

        assert_equal("ok", response["status"])
        project = project_store.resolve(response["project_id"])
        refute_nil(project)
        assert_equal("obelix", project.name)
        assert_equal(true, File.directory?(File.join(bootstrap.projects_root, "obelix")))
      end
    end
  end

  def test_send_dispatch_creates_project_from_explicit_operational_intent_with_project_ref_arg
    Dir.mktmpdir("redwright-server-dispatcher-project-new-operational-project-ref-") do |dir|
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
          projects_root: bootstrap.projects_root,
          task_store: Redwright::TaskStore.new(bootstrap.db_path),
          action_execution_store: Redwright::ActionExecutionStore.new(bootstrap.db_path)
        )

        response = dispatcher.call(
          "type" => "send",
          "session_id" => "telegram-42",
          "payload" => {
            "channel" => "telegram",
            "project_ref" => "rw",
            "intent" => "change",
            "message" => "Create a new project named sesame",
            "actions" => [],
            "operational_intent" => "project_new",
            "operational_args" => { "project_ref" => "sesame" }
          }
        )

        assert_equal("ok", response["status"])
        project = project_store.resolve(response["project_id"])
        refute_nil(project)
        assert_equal("sesame", project.name)
        assert_equal(true, File.directory?(File.join(bootstrap.projects_root, "sesame")))
      end
    end
  end

  def test_send_dispatch_delegates_project_new_operational_intent_to_mediator
    Dir.mktmpdir("redwright-server-dispatcher-project-new-mediator-operational-") do |dir|
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

        calls = []
        mediator = Object.new
        mediator.define_singleton_method(:parse_operational_intent) do |intent:, args:|
          calls << { intent: intent, args: args }
          { command: "new", name: "mediated-project" }
        end
        mediator.define_singleton_method(:parse_project_slash) do |raw:|
          _ = raw
          nil
        end

        dispatcher = Redwright::ServerRuntimeDispatcher.new(
          flow: flow,
          blocked_retry_attempts: 1,
          project_store: project_store,
          projects_root: bootstrap.projects_root,
          project_new_mediator: mediator
        )

        response = dispatcher.call(
          "type" => "send",
          "session_id" => "telegram-42",
          "payload" => {
            "channel" => "telegram",
            "project_ref" => "rw",
            "intent" => "change",
            "message" => "create project",
            "actions" => [],
            "operational_intent" => "project_new",
            "operational_args" => { "project_name" => "ignored-by-mediator" }
          }
        )

        assert_equal("ok", response["status"])
        project = project_store.resolve(response["project_id"])
        assert_equal("mediated-project", project.name)
        assert_equal(1, calls.size)
        assert_equal("project_new", calls.first[:intent])
      end
    end
  end

  def test_send_dispatch_delegates_project_new_slash_to_mediator
    Dir.mktmpdir("redwright-server-dispatcher-project-new-mediator-slash-") do |dir|
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

        slash_calls = []
        mediator = Object.new
        mediator.define_singleton_method(:parse_operational_intent) do |intent:, args:|
          _ = intent
          _ = args
          nil
        end
        mediator.define_singleton_method(:parse_project_slash) do |raw:|
          slash_calls << raw
          { command: "new", name: "slash-mediated-project" }
        end

        dispatcher = Redwright::ServerRuntimeDispatcher.new(
          flow: flow,
          blocked_retry_attempts: 1,
          project_store: project_store,
          projects_root: bootstrap.projects_root,
          project_new_mediator: mediator
        )

        response = dispatcher.call(
          "type" => "send",
          "session_id" => "telegram-42",
          "payload" => {
            "channel" => "telegram",
            "project_ref" => "rw",
            "intent" => "change",
            "message" => "/project new any-name",
            "actions" => []
          }
        )

        assert_equal("ok", response["status"])
        project = project_store.resolve(response["project_id"])
        assert_equal("slash-mediated-project", project.name)
        assert_equal(["/project new any-name"], slash_calls)
      end
    end
  end

  def test_send_dispatch_clones_repo_from_repo_clone_slash_and_binds_session_context
    Dir.mktmpdir("redwright-server-dispatcher-repo-clone-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)

        remote_repo = File.join(dir, "remote.git")
        work_repo = File.join(dir, "work")
        FileUtils.mkdir_p(work_repo)
        run_cmd!("git init --bare #{remote_repo}")
        Dir.chdir(work_repo) do
          run_cmd!("git init .")
          run_cmd!("git config user.name 'rw-test'")
          run_cmd!("git config user.email 'rw-test@example.com'")
          File.write("README.md", "# sample\n")
          run_cmd!("git add README.md")
          run_cmd!("git commit -m 'init'")
          run_cmd!("git remote add origin #{remote_repo}")
          run_cmd!("git push -u origin HEAD")
        end

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
          projects_root: bootstrap.projects_root,
          task_store: Redwright::TaskStore.new(bootstrap.db_path),
          action_execution_store: Redwright::ActionExecutionStore.new(bootstrap.db_path)
        )

        clone_response = dispatcher.call(
          "type" => "send",
          "session_id" => "telegram-99",
          "payload" => {
            "channel" => "telegram",
            "project_ref" => "rw",
            "intent" => "change",
            "message" => "/repo clone #{remote_repo}",
            "actions" => []
          }
        )

        assert_equal("ok", clone_response["status"])
        project = project_store.resolve(clone_response["project_id"])
        refute_nil(project)
        assert_equal("remote_clone", project.source_type)
        assert_equal(remote_repo, project.source_ref)
        assert_equal(true, File.directory?(File.join(project.path, ".git")))
        manifest_path = File.join(project.path, ".redwright", "manifest.yml")
        assert_equal(true, File.file?(manifest_path))
        manifest = YAML.safe_load(File.read(manifest_path))
        assert_equal(1, manifest["schema_version"])
        assert_equal(project.id, manifest.dig("project", "id"))
        assert_equal(project.name, manifest.dig("project", "name"))
        assert_equal("clone", manifest.dig("project", "created_via"))
        assert_equal(remote_repo, manifest.dig("provenance", "remote_url"))
        refute_nil(manifest.dig("provenance", "provider"))
        refute_nil(manifest.dig("provenance", "ref"))

        follow_up = dispatcher.call(
          "type" => "send",
          "session_id" => "telegram-99",
          "payload" => {
            "channel" => "telegram",
            "project_ref" => "does-not-exist",
            "intent" => "change",
            "message" => "continue implementation",
            "actions" => []
          }
        )

        assert_equal("ok", follow_up["status"])
        assert_equal(project.id, follow_up["project_id"])
        assert_equal(project.id, project_store.resolve(project.name).id)
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
          projects_root: bootstrap.projects_root,
          task_store: Redwright::TaskStore.new(bootstrap.db_path),
          action_execution_store: Redwright::ActionExecutionStore.new(bootstrap.db_path)
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

  def test_send_dispatch_project_list_returns_registered_projects_without_flow_execution
    Dir.mktmpdir("redwright-server-dispatcher-project-list-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        alpha_path = File.join(bootstrap.projects_root, "alpha")
        beta_path = File.join(bootstrap.projects_root, "beta")
        FileUtils.mkdir_p(alpha_path)
        FileUtils.mkdir_p(beta_path)
        project_store.register(path: alpha_path, aliases: ["alpha"])
        project_store.register(path: beta_path, aliases: ["beta"])

        flow = Object.new
        flow.define_singleton_method(:process) do |**_kwargs|
          raise "flow should not run for /project list"
        end
        dispatcher = Redwright::ServerRuntimeDispatcher.new(
          flow: flow,
          blocked_retry_attempts: 1,
          project_store: project_store,
          projects_root: bootstrap.projects_root
        )

        response = dispatcher.call(
          "type" => "send",
          "session_id" => "telegram-88",
          "payload" => {
            "channel" => "telegram",
            "project_ref" => "",
            "intent" => "change",
            "message" => "/project list",
            "actions" => []
          }
        )

        assert_equal("ok", response["status"])
        assert_equal("project_list", response["command"])
        names = response.fetch("projects").map { |p| p.fetch("name") }.sort
        assert_equal(%w[alpha beta], names)
      end
    end
  end

  def test_send_dispatch_repo_status_returns_git_status_for_active_project_without_flow_execution
    Dir.mktmpdir("redwright-server-dispatcher-repo-status-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        path = File.join(bootstrap.projects_root, "alpha")
        FileUtils.mkdir_p(path)
        run_cmd!("git -C #{path} init .")
        run_cmd!("git -C #{path} config user.name 'rw-test'")
        run_cmd!("git -C #{path} config user.email 'rw-test@example.com'")
        File.write(File.join(path, "README.md"), "v1\n")
        run_cmd!("git -C #{path} add README.md")
        run_cmd!("git -C #{path} commit -m 'init'")
        project = project_store.register(path: path, aliases: ["alpha"])
        project_store.mark_active(project.id)

        flow = Object.new
        flow.define_singleton_method(:process) do |**_kwargs|
          raise "flow should not run for /repo status"
        end
        dispatcher = Redwright::ServerRuntimeDispatcher.new(
          flow: flow,
          blocked_retry_attempts: 1,
          project_store: project_store,
          projects_root: bootstrap.projects_root
        )

        response = dispatcher.call(
          "type" => "send",
          "session_id" => "telegram-89",
          "payload" => {
            "channel" => "telegram",
            "project_ref" => "",
            "intent" => "change",
            "message" => "/repo status",
            "actions" => []
          }
        )

        assert_equal("ok", response["status"])
        assert_equal("repo_status", response["command"])
        assert_equal(project.id, response["project_id"])
        assert_match("##", response["git_status"])
      end
    end
  end

  def test_send_dispatch_ticket_list_returns_recent_project_tickets_without_flow_execution
    Dir.mktmpdir("redwright-server-dispatcher-ticket-list-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        workstream_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        path = File.join(bootstrap.projects_root, "alpha")
        FileUtils.mkdir_p(path)
        project = project_store.register(path: path, aliases: ["alpha"])
        workstream = workstream_store.create(project_id: project.id, intent: "change", state: "executing")
        task_store.create(workstream_id: workstream.id, description: "First ticketized request", status: "pending", trace_id: "trc-ticket-1")

        flow = Object.new
        flow.define_singleton_method(:process) do |**_kwargs|
          raise "flow should not run for /ticket list"
        end
        dispatcher = Redwright::ServerRuntimeDispatcher.new(
          flow: flow,
          blocked_retry_attempts: 1,
          project_store: project_store,
          projects_root: bootstrap.projects_root,
          task_store: task_store
        )

        response = dispatcher.call(
          "type" => "send",
          "session_id" => "telegram-91",
          "payload" => {
            "channel" => "telegram",
            "project_ref" => "alpha",
            "intent" => "change",
            "message" => "/ticket list",
            "actions" => []
          }
        )

        assert_equal("ok", response["status"])
        assert_equal("ticket_list", response["command"])
        assert_equal(project.id, response["project_id"])
        assert_equal(1, response.fetch("tickets").size)
        assert_match("First ticketized request", response.fetch("tickets").first.fetch("description"))
      end
    end
  end

  def test_send_dispatch_ticketizes_adhoc_message_for_telegram_channel
    flow = Object.new
    captured = {}
    flow.define_singleton_method(:process) do |**kwargs|
      captured.merge!(kwargs)
      Struct.new(:project, :workstream, :task, :terminal_reason, :action_results, keyword_init: true).new(
        project: Struct.new(:id).new("p-1"),
        workstream: Struct.new(:id, :state).new("ws-1", "executing"),
        task: Struct.new(:id).new("task-1"),
        terminal_reason: "ok",
        action_results: []
      )
    end
    dispatcher = Redwright::ServerRuntimeDispatcher.new(flow: flow, blocked_retry_attempts: 1)

    response = dispatcher.call(
      "type" => "send",
      "session_id" => "telegram-92",
      "payload" => {
        "channel" => "telegram",
        "project_ref" => "p-1",
        "intent" => "change",
        "message" => "implement parser",
        "actions" => []
      }
    )

    assert_equal("ok", response["status"])
    assert_equal(true, response["ticketized"])
    assert_equal("Ticket request: implement parser", captured[:message])
  end

  def test_send_dispatch_repo_undo_executes_git_undo_when_last_task_is_git_only
    Dir.mktmpdir("redwright-server-dispatcher-repo-undo-ok-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        action_store = Redwright::ActionExecutionStore.new(bootstrap.db_path)
        path = File.join(bootstrap.projects_root, "alpha")
        FileUtils.mkdir_p(path)
        run_cmd!("git -C #{path} init .")
        run_cmd!("git -C #{path} config user.name 'rw-test'")
        run_cmd!("git -C #{path} config user.email 'rw-test@example.com'")
        File.write(File.join(path, "README.md"), "v1\n")
        run_cmd!("git -C #{path} add README.md")
        run_cmd!("git -C #{path} commit -m 'init'")
        project = project_store.register(path: path, aliases: ["alpha"])

        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: Redwright::WorkstreamStore.new(bootstrap.db_path),
          task_store: task_store,
          alignment_store: Redwright::AlignmentStore.new(bootstrap.db_path),
          alignment_interruption_store: Redwright::AlignmentInterruptionStore.new(bootstrap.db_path),
          primitive_executor: Redwright::PrimitiveExecutor.new(
            allowed_projects_root: bootstrap.projects_root,
            enforce_mutating_projects_root: true
          ),
          action_execution_store: action_store
        )
        dispatcher = Redwright::ServerRuntimeDispatcher.new(
          flow: flow,
          blocked_retry_attempts: 1,
          project_store: project_store,
          projects_root: bootstrap.projects_root,
          task_store: task_store,
          action_execution_store: action_store
        )

        dispatcher.call(
          "type" => "send",
          "session_id" => "telegram-undo-1",
          "payload" => {
            "channel" => "telegram",
            "project_ref" => "alpha",
            "intent" => "change",
            "message" => "create git commit",
            "actions" => [
              {
                "id" => "c1",
                "type" => "git_commit",
                "args" => { "message" => "tracked", "add_all" => true, "confirmed" => true },
                "requires_confirmation" => true,
                "timeout_ms" => 10_000,
                "on_failure" => "abort"
              }
            ]
          }
        )

        File.write(File.join(path, "README.md"), "v2\n")
        undo = dispatcher.call(
          "type" => "send",
          "session_id" => "telegram-undo-1",
          "payload" => {
            "channel" => "telegram",
            "project_ref" => project.id,
            "intent" => "change",
            "message" => "/repo undo",
            "actions" => []
          }
        )

        assert_equal("ok", undo["status"])
        assert_equal(project.id, undo["project_id"])
        assert_equal("v1\n", File.read(File.join(path, "README.md")))
      end
    end
  end

  def test_send_dispatch_repo_undo_blocks_mixed_git_and_non_git_last_task
    Dir.mktmpdir("redwright-server-dispatcher-repo-undo-mixed-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        action_store = Redwright::ActionExecutionStore.new(bootstrap.db_path)
        path = File.join(bootstrap.projects_root, "alpha")
        FileUtils.mkdir_p(path)
        run_cmd!("git -C #{path} init .")
        run_cmd!("git -C #{path} config user.name 'rw-test'")
        run_cmd!("git -C #{path} config user.email 'rw-test@example.com'")
        File.write(File.join(path, "README.md"), "v1\n")
        run_cmd!("git -C #{path} add README.md")
        run_cmd!("git -C #{path} commit -m 'init'")
        project_store.register(path: path, aliases: ["alpha"])

        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: Redwright::WorkstreamStore.new(bootstrap.db_path),
          task_store: task_store,
          alignment_store: Redwright::AlignmentStore.new(bootstrap.db_path),
          alignment_interruption_store: Redwright::AlignmentInterruptionStore.new(bootstrap.db_path),
          primitive_executor: Redwright::PrimitiveExecutor.new(
            allowed_projects_root: bootstrap.projects_root,
            enforce_mutating_projects_root: true
          ),
          action_execution_store: action_store
        )
        dispatcher = Redwright::ServerRuntimeDispatcher.new(
          flow: flow,
          blocked_retry_attempts: 1,
          project_store: project_store,
          projects_root: bootstrap.projects_root,
          task_store: task_store,
          action_execution_store: action_store
        )

        dispatcher.call(
          "type" => "send",
          "session_id" => "telegram-undo-2",
          "payload" => {
            "channel" => "telegram",
            "project_ref" => "alpha",
            "intent" => "change",
            "message" => "mixed task",
            "actions" => [
              {
                "id" => "w1",
                "type" => "write_file",
                "args" => { "path" => "notes.txt", "content" => "x\n" },
                "requires_confirmation" => false,
                "timeout_ms" => 10_000,
                "on_failure" => "abort"
              },
              {
                "id" => "g1",
                "type" => "git_status",
                "args" => {},
                "requires_confirmation" => false,
                "timeout_ms" => 10_000,
                "on_failure" => "abort"
              }
            ]
          }
        )

        undo = dispatcher.call(
          "type" => "send",
          "session_id" => "telegram-undo-2",
          "payload" => {
            "channel" => "telegram",
            "project_ref" => "alpha",
            "intent" => "change",
            "message" => "/repo undo",
            "actions" => []
          }
        )

        assert_equal("error", undo["status"])
        assert_equal("undo_blocked_mixed_git_and_non_git_actions", undo["message"])
      end
    end
  end

  private

  def run_cmd!(cmd)
    out, err, status = Open3.capture3(cmd)
    return if status.success?

    raise "command failed: #{cmd}\nstdout: #{out}\nstderr: #{err}"
  end
end
