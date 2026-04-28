# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "stringio"
require "json"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/workstream_store"
require "redwright/task_store"
require "redwright/action_execution_store"
require "redwright/alignment_store"
require "redwright/alignment_interruption_store"
require "redwright/runtime_flow"
require "redwright/primitive_executor"
require "redwright/telegram_runtime_handler"
require "redwright/chat_context_store"
require "redwright/clarification_session_store"
require "redwright/telegram_context_resolver"
require "redwright/daemon_runner"
require "redwright/simulated_ingress_adapter"

class SimulatedIngressE2ETest < Minitest::Test
  FakeDecision = Struct.new(:intent, :message, :actions, :gaps, :source, :finish_reason, :raw_output, keyword_init: true)

  class ScriptedInterpreter
    def interpret(text:, model:, **_kwargs)
      down = text.downcase
      if down.include?("alpha write")
        return FakeDecision.new(
          intent: "change",
          message: "write alpha note",
          actions: [write_action(id: "write_alpha", path: "notes/alpha.txt", content: "alpha-note\n")],
          source: "llm",
          finish_reason: "stop",
          raw_output: "{}"
        )
      end
      if down.include?("beta write")
        return FakeDecision.new(
          intent: "change",
          message: "write beta note",
          actions: [write_action(id: "write_beta", path: "notes/beta.txt", content: "beta-note\n")],
          source: "llm",
          finish_reason: "stop",
          raw_output: "{}"
        )
      end
      if down.include?("second write")
        return FakeDecision.new(
          intent: "change",
          message: "write alpha second note",
          actions: [write_action(id: "write_alpha_2", path: "notes/alpha-2.txt", content: "alpha-second\n")],
          source: "llm",
          finish_reason: "stop",
          raw_output: "{}"
        )
      end

      FakeDecision.new(
        intent: "meta",
        message: text,
        actions: [],
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    private

    def write_action(id:, path:, content:)
      {
        "id" => id,
        "type" => "write_file",
        "args" => {
          "path" => path,
          "content" => content
        },
        "requires_confirmation" => false,
        "timeout_ms" => 10_000,
        "on_failure" => "abort"
      }
    end
  end

  class PlanningThenFeatureInterpreter
    FakeDecision = Struct.new(:intent, :message, :actions, :source, :finish_reason, :raw_output, keyword_init: true)

    def interpret(text:, model:, **_kwargs)
      down = text.downcase
      if down.include?("add due date")
        return FakeDecision.new(
          intent: "change",
          message: "implement due date support",
          actions: [
            {
              "id" => "write_todo",
              "type" => "write_file",
              "args" => {
                "path" => "todo/README.md",
                "content" => "Todo app with due date support\n"
              },
              "requires_confirmation" => false,
              "timeout_ms" => 10_000,
              "on_failure" => "abort"
            }
          ],
          source: "llm",
          finish_reason: "stop",
          raw_output: "{}"
        )
      end
      if down.include?("plan ") || down.include?("single-user") || down.include?("cli input") || down.include?("ruby layers")
        return FakeDecision.new(intent: "plan", message: text, actions: [], source: "llm", finish_reason: "stop", raw_output: "{}")
      end

      FakeDecision.new(intent: "meta", message: text, actions: [], source: "llm", finish_reason: "stop", raw_output: "{}")
    end
  end

  class InferredNameInterpreter
    def interpret(text:, model:, **_kwargs)
      down = text.downcase
      if down.include?("build cli") || down.include?("write starter")
        return FakeDecision.new(
          intent: "change",
          message: "write starter file",
          actions: [
            {
              "id" => "write_starter",
              "type" => "write_file",
              "args" => { "path" => "README.md", "content" => "starter\n" },
              "requires_confirmation" => false,
              "timeout_ms" => 10_000,
              "on_failure" => "abort"
            }
          ],
          source: "llm",
          finish_reason: "stop",
          raw_output: "{}"
        )
      end

      FakeDecision.new(intent: "meta", message: text, actions: [], source: "llm", finish_reason: "stop", raw_output: "{}")
    end
  end

  class RetryQualityInterpreter
    def interpret(text:, model:, **_kwargs)
      FakeDecision.new(
        intent: "change",
        message: "write converged file",
        actions: [
          {
            "id" => "write_converged",
            "type" => "write_file",
            "args" => { "path" => "runtime/converged.txt", "content" => "ok\n" },
            "requires_confirmation" => false,
            "timeout_ms" => 10_000,
            "on_failure" => "abort"
          }
        ],
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end
  end

  class PlannerGapThenExecuteInterpreter
    attr_reader :seen_texts

    def initialize
      @seen_texts = []
      @asked = false
    end

    def interpret(text:, model:, **_kwargs)
      @seen_texts << text
      unless @asked
        @asked = true
        return FakeDecision.new(
          intent: "change",
          message: "Create guess number CLI with tests",
          actions: [],
          gaps: [
            {
              "id" => "gap-framework",
              "question" => "Which test framework do you prefer?",
              "field" => "test_framework",
              "inferred_value" => "RSpec",
              "resolved" => false,
              "priority" => 1
            }
          ],
          source: "llm",
          finish_reason: "stop",
          raw_output: "{}"
        )
      end

      FakeDecision.new(
        intent: "change",
        message: "write app after clarification",
        actions: [
          {
            "id" => "write_after_gap",
            "type" => "write_file",
            "args" => { "path" => "README.md", "content" => "created\n" },
            "requires_confirmation" => false,
            "timeout_ms" => 10_000,
            "on_failure" => "abort"
          }
        ],
        gaps: [],
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end
  end

  def with_test_root(name)
    keep = ENV["KEEP_TEST_WORKSPACE"] == "1"
    if keep
      root = File.join(Dir.pwd, "_workspace", "tmp", "testing", "e2e", name)
      FileUtils.rm_rf(root)
      FileUtils.mkdir_p(root)
      yield root
      puts "E2E_TEST_ROOT=#{root}"
      return
    end

    Dir.mktmpdir("redwright-simulated-e2e-#{name}-") do |dir|
      yield dir
    end
  end

  def test_simulated_ingress_handles_multi_turn_multi_project_pause_resume_and_fs_effects
    with_test_root("complex") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        workstream_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        chat_context_store = Redwright::ChatContextStore.new(bootstrap.db_path)

        alpha_path = File.join(bootstrap.projects_root, "alpha")
        beta_path = File.join(bootstrap.projects_root, "beta")
        FileUtils.mkdir_p(alpha_path)
        FileUtils.mkdir_p(beta_path)

        alpha = project_store.register(path: alpha_path, aliases: ["rw-alpha"])
        beta = project_store.register(path: beta_path, aliases: ["rw-beta"])

        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: workstream_store,
          task_store: task_store,
          alignment_store: Redwright::AlignmentStore.new(bootstrap.db_path),
          alignment_interruption_store: Redwright::AlignmentInterruptionStore.new(bootstrap.db_path),
          primitive_executor: Redwright::PrimitiveExecutor.new(
            allowed_projects_root: bootstrap.projects_root,
            enforce_mutating_projects_root: true
          )
        )

        resolver = Redwright::TelegramContextResolver.new(
          project_store: project_store,
          chat_context_store: chat_context_store,
          projects_root: bootstrap.projects_root
        )

        ingress = Redwright::SimulatedIngressAdapter.new(
          events: [
            Redwright::SimulatedIngressAdapter.event(external_message_id: 1, external_chat_id: 77, text: "rw-alpha alpha write"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 2, external_chat_id: 77, text: "pause now"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 3, external_chat_id: 77, text: "resume now"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 4, external_chat_id: 77, text: "rw-beta beta write"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 5, external_chat_id: 77, text: "rw-alpha second write")
          ]
        )

        handler = Redwright::TelegramRuntimeHandler.new(
          flow: flow,
          telegram_client: ingress,
          out: StringIO.new,
          err: StringIO.new,
          context_resolver: resolver,
          chat_context_store: chat_context_store,
          blocked_retry_attempts: 1,
          intent_interpreter: ScriptedInterpreter.new
        )

        cursor = nil
        runner = Redwright::DaemonRunner.new(
          ingress_poller: lambda {
            poll = ingress.poll(cursor: cursor, timeout_seconds: 0)
            cursor = poll.next_cursor
            poll.events
          },
          event_handler: ->(event) { handler.handle(event) }
        )
        runner.run(loop_interval_seconds: 0.0, max_iterations: 1)

        assert(File.file?(File.join(alpha_path, "notes", "alpha.txt")))
        assert(File.file?(File.join(alpha_path, "notes", "alpha-2.txt")))
        assert(File.file?(File.join(beta_path, "notes", "beta.txt")))
        assert_equal("alpha-note\n", File.read(File.join(alpha_path, "notes", "alpha.txt")))
        assert_equal("beta-note\n", File.read(File.join(beta_path, "notes", "beta.txt")))

        tasks = task_store.list
        assert_operator(tasks.size, :>=, 4)
        assert(tasks.any? { |t| t.description.include?("pause workstream") })

        alpha_ws = workstream_store.find_latest_for_project(project_id: alpha.id)
        beta_ws = workstream_store.find_latest_for_project(project_id: beta.id)
        assert_equal("executing", alpha_ws.state)
        assert_equal("executing", beta_ws.state)
      end
    end
  end

  def test_simulated_ingress_happy_path_plan_then_feature_change
    with_test_root("happy") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        workstream_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        chat_context_store = Redwright::ChatContextStore.new(bootstrap.db_path)

        todo_path = File.join(bootstrap.projects_root, "todo-app")
        FileUtils.mkdir_p(todo_path)
        project = project_store.register(path: todo_path, aliases: ["rw-todo"])

        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: workstream_store,
          task_store: task_store,
          alignment_store: Redwright::AlignmentStore.new(bootstrap.db_path),
          alignment_interruption_store: Redwright::AlignmentInterruptionStore.new(bootstrap.db_path),
          primitive_executor: Redwright::PrimitiveExecutor.new(
            allowed_projects_root: bootstrap.projects_root,
            enforce_mutating_projects_root: true
          )
        )

        resolver = Redwright::TelegramContextResolver.new(
          project_store: project_store,
          chat_context_store: chat_context_store,
          projects_root: bootstrap.projects_root
        )

        ingress = Redwright::SimulatedIngressAdapter.new(
          events: [
            Redwright::SimulatedIngressAdapter.event(external_message_id: 1, external_chat_id: 88, text: "rw-todo plan a todo app"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 2, external_chat_id: 88, text: "single-user and local"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 3, external_chat_id: 88, text: "cli input output and file persistence"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 4, external_chat_id: 88, text: "ruby layers and sqlite"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 5, external_chat_id: 88, text: "rw-todo add due date feature")
          ]
        )

        handler = Redwright::TelegramRuntimeHandler.new(
          flow: flow,
          telegram_client: ingress,
          out: StringIO.new,
          err: StringIO.new,
          context_resolver: resolver,
          chat_context_store: chat_context_store,
          blocked_retry_attempts: 1,
          intent_interpreter: PlanningThenFeatureInterpreter.new
        )

        cursor = nil
        runner = Redwright::DaemonRunner.new(
          ingress_poller: lambda {
            poll = ingress.poll(cursor: cursor, timeout_seconds: 0)
            cursor = poll.next_cursor
            poll.events
          },
          event_handler: ->(event) { handler.handle(event) }
        )
        runner.run(loop_interval_seconds: 0.0, max_iterations: 1)

        assert(File.file?(File.join(todo_path, "todo", "README.md")))
        assert_equal("Todo app with due date support\n", File.read(File.join(todo_path, "todo", "README.md")))

        tasks = task_store.list
        assert(tasks.any? { |t| t.description == "alignment complete" })
        assert(tasks.any? { |t| t.description == "implement due date support" })
        assert_operator(tasks.size, :>=, 3)
        latest = workstream_store.find_latest_for_project(project_id: project.id)
        assert_equal("executing", latest.state)
      end
    end
  end

  def test_simulated_ingress_inferred_name_confirmation_flow
    with_test_root("inferred_name") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :test).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        workstream_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        chat_context_store = Redwright::ChatContextStore.new(bootstrap.db_path)

        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: workstream_store,
          task_store: task_store,
          alignment_store: Redwright::AlignmentStore.new(bootstrap.db_path),
          primitive_executor: Redwright::PrimitiveExecutor.new(
            allowed_projects_root: bootstrap.projects_root,
            enforce_mutating_projects_root: true
          )
        )

        resolver = Redwright::TelegramContextResolver.new(
          project_store: project_store,
          chat_context_store: chat_context_store,
          projects_root: bootstrap.projects_root
        )

        ingress = Redwright::SimulatedIngressAdapter.new(
          events: [
            Redwright::SimulatedIngressAdapter.event(external_message_id: 1, external_chat_id: 91, text: "Create a tiny project named hello-cli and build cli"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 2, external_chat_id: 91, text: "yes"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 3, external_chat_id: 91, text: "write starter")
          ]
        )

        handler = Redwright::TelegramRuntimeHandler.new(
          flow: flow,
          telegram_client: ingress,
          out: StringIO.new,
          err: StringIO.new,
          context_resolver: resolver,
          chat_context_store: chat_context_store,
          blocked_retry_attempts: 1,
          intent_interpreter: InferredNameInterpreter.new
        )

        cursor = nil
        runner = Redwright::DaemonRunner.new(
          ingress_poller: lambda {
            poll = ingress.poll(cursor: cursor, timeout_seconds: 0)
            cursor = poll.next_cursor
            poll.events
          },
          event_handler: ->(event) { handler.handle(event) }
        )
        runner.run(loop_interval_seconds: 0.0, max_iterations: 1)

        project_path = File.join(bootstrap.projects_root, "hello-cli")
        assert(File.directory?(project_path))
        assert(File.file?(File.join(project_path, "README.md")))
        assert_match("I inferred project name 'hello-cli'", ingress.sent_messages.map { |m| m[:text] }.join("\n"))
      end
    end
  end

  def test_simulated_ingress_multi_gap_single_reply_consumption
    with_test_root("multi_gap") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :test).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        workstream_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        chat_context_store = Redwright::ChatContextStore.new(bootstrap.db_path)

        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: workstream_store,
          task_store: task_store,
          alignment_store: Redwright::AlignmentStore.new(bootstrap.db_path),
          primitive_executor: Redwright::PrimitiveExecutor.new(
            allowed_projects_root: bootstrap.projects_root,
            enforce_mutating_projects_root: true
          )
        )

        resolver = Redwright::TelegramContextResolver.new(
          project_store: project_store,
          chat_context_store: chat_context_store,
          projects_root: bootstrap.projects_root
        )

        ingress = Redwright::SimulatedIngressAdapter.new(
          events: [
            Redwright::SimulatedIngressAdapter.event(external_message_id: 1, external_chat_id: 92, text: "start project called sample-one"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 2, external_chat_id: 92, text: "better use sample-two and module example.com/sample-two"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 3, external_chat_id: 92, text: "write starter")
          ]
        )

        handler = Redwright::TelegramRuntimeHandler.new(
          flow: flow,
          telegram_client: ingress,
          out: StringIO.new,
          err: StringIO.new,
          context_resolver: resolver,
          chat_context_store: chat_context_store,
          blocked_retry_attempts: 1,
          intent_interpreter: InferredNameInterpreter.new
        )

        cursor = nil
        runner = Redwright::DaemonRunner.new(
          ingress_poller: lambda {
            poll = ingress.poll(cursor: cursor, timeout_seconds: 0)
            cursor = poll.next_cursor
            poll.events
          },
          event_handler: ->(event) { handler.handle(event) }
        )
        runner.run(loop_interval_seconds: 0.0, max_iterations: 1)

        sample_two = File.join(bootstrap.projects_root, "sample-two")
        assert(File.directory?(sample_two))
        assert(File.file?(File.join(sample_two, "README.md")))
      end
    end
  end

  def test_simulated_ingress_convergence_retry_persists_actions_and_terminal_reason
    with_test_root("converge_retry") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :test).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        workstream_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        action_store = Redwright::ActionExecutionStore.new(bootstrap.db_path)
        chat_context_store = Redwright::ChatContextStore.new(bootstrap.db_path)

        project_path = File.join(bootstrap.projects_root, "retry-proj")
        FileUtils.mkdir_p(project_path)
        project = project_store.register(path: project_path, aliases: ["rw-retry"])

        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: workstream_store,
          task_store: task_store,
          alignment_store: Redwright::AlignmentStore.new(bootstrap.db_path),
          primitive_executor: Redwright::PrimitiveExecutor.new(
            allowed_projects_root: bootstrap.projects_root,
            enforce_mutating_projects_root: true
          ),
          action_execution_store: action_store
        )

        resolver = Redwright::TelegramContextResolver.new(
          project_store: project_store,
          chat_context_store: chat_context_store,
          projects_root: bootstrap.projects_root
        )

        quality_calls = 0
        quality_runner = Object.new
        quality_runner.define_singleton_method(:run) do |**_kwargs|
          quality_calls += 1
          if quality_calls == 1
            [Struct.new(:name, :status).new("test", "error")]
          else
            [Struct.new(:name, :status).new("test", "ok")]
          end
        end

        prompt_loader = Object.new
        prompt_loader.define_singleton_method(:build) do |**_kwargs|
          { quality: { auto_validate: true, lint_command: nil, test_command: "bundle exec rake test" } }
        end

        ingress = Redwright::SimulatedIngressAdapter.new(
          events: [
            Redwright::SimulatedIngressAdapter.event(external_message_id: 1, external_chat_id: 93, text: "rw-retry do work")
          ]
        )

        handler = Redwright::TelegramRuntimeHandler.new(
          flow: flow,
          telegram_client: ingress,
          out: StringIO.new,
          err: StringIO.new,
          context_resolver: resolver,
          chat_context_store: chat_context_store,
          blocked_retry_attempts: 2,
          intent_interpreter: RetryQualityInterpreter.new,
          prompt_context_loader: prompt_loader,
          quality_gate_runner: quality_runner,
          send_json_envelope: true
        )

        cursor = nil
        runner = Redwright::DaemonRunner.new(
          ingress_poller: lambda {
            poll = ingress.poll(cursor: cursor, timeout_seconds: 0)
            cursor = poll.next_cursor
            poll.events
          },
          event_handler: ->(event) { handler.handle(event) }
        )
        runner.run(loop_interval_seconds: 0.0, max_iterations: 1)

        assert_equal(2, quality_calls)
        assert(File.file?(File.join(project_path, "runtime", "converged.txt")))
        tasks = task_store.list
        assert_operator(tasks.size, :>=, 2)
        latest_task = tasks.first
        actions = action_store.list(task_id: latest_task.id)
        assert(actions.any? { |a| a.action_id == "write_converged" && a.status == "ok" })

        payload_msg = ingress.sent_messages.find { |m| m[:text].start_with?("```json") }
        refute_nil(payload_msg)
        json_text = payload_msg[:text].sub(/\A```json\n/, "").sub(/\n```\z/, "")
        payload = JSON.parse(json_text)
        assert_equal("ok", payload["status"])
        assert_equal("success", payload.dig("runtime", "terminal_reason"))
        assert_equal(2, payload.dig("runtime", "execution", "attempts"))
      end
    end
  end

  def test_simulated_ingress_consumes_short_gap_answer_without_meta_drift
    with_test_root("planner_gap_answer") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        workstream_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        chat_context_store = Redwright::ChatContextStore.new(bootstrap.db_path)
        clarification_session_store = Redwright::ClarificationSessionStore.new(bootstrap.db_path)

        project_path = File.join(bootstrap.projects_root, "project-one")
        FileUtils.mkdir_p(project_path)
        project_store.register(path: project_path, aliases: ["rw"])

        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: workstream_store,
          task_store: task_store,
          alignment_store: Redwright::AlignmentStore.new(bootstrap.db_path),
          primitive_executor: Redwright::PrimitiveExecutor.new(
            allowed_projects_root: bootstrap.projects_root,
            enforce_mutating_projects_root: true
          )
        )

        resolver = Redwright::TelegramContextResolver.new(
          project_store: project_store,
          chat_context_store: chat_context_store,
          projects_root: bootstrap.projects_root,
          clarification_session_store: clarification_session_store
        )

        ingress = Redwright::SimulatedIngressAdapter.new(
          events: [
            Redwright::SimulatedIngressAdapter.event(external_message_id: 1, external_chat_id: 100, text: "Create guess-number CLI in rw"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 2, external_chat_id: 100, text: "RSpec")
          ]
        )

        interpreter = PlannerGapThenExecuteInterpreter.new
        handler = Redwright::TelegramRuntimeHandler.new(
          flow: flow,
          telegram_client: ingress,
          out: StringIO.new,
          err: StringIO.new,
          context_resolver: resolver,
          chat_context_store: chat_context_store,
          clarification_session_store: clarification_session_store,
          blocked_retry_attempts: 1,
          intent_interpreter: interpreter
        )

        cursor = nil
        runner = Redwright::DaemonRunner.new(
          ingress_poller: lambda {
            poll = ingress.poll(cursor: cursor, timeout_seconds: 0)
            cursor = poll.next_cursor
            poll.events
          },
          event_handler: ->(event) { handler.handle(event) }
        )
        runner.run(loop_interval_seconds: 0.0, max_iterations: 1)

        assert(File.file?(File.join(project_path, "README.md")))
        assert_includes(interpreter.seen_texts.last, "Clarification for test_framework: RSpec")
        assert_nil(clarification_session_store.get_open(chat_id: 100))
      end
    end
  end
end
