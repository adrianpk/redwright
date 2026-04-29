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

class SimulatedIngressMatrixTest < Minitest::Test
  FakeDecision = Struct.new(
    :intent,
    :message,
    :actions,
    :gaps,
    :control_intent,
    :control_scope,
    :source,
    :finish_reason,
    :raw_output,
    keyword_init: true
  )

  class MatrixInterpreter
    def interpret(text:, model:, **_kwargs)
      down = text.downcase
      return stop_asking_decision if down.include?("no more questions")
      return project_gap_decision if down.include?("build widget")
      return write_decision(path: "starter/README.md", content: "starter\n", message: "write starter") if down.include?("write starter")
      return write_decision(path: "seed.txt", content: "seed\n", message: "create seed") if down.include?("start work")
      return control_decision(intent: "cancel_task", scope: "task", message: "cancel current task") if down.include?("cancel current")
      return control_decision(intent: "cancel_all", scope: "chat", message: "cancel all runtime") if down.include?("cancel all")
      return write_decision(path: "runtime/converged.txt", content: "ok\n", message: "write converged") if down.include?("do work")

      FakeDecision.new(intent: "meta", message: text, actions: [], gaps: [], source: "llm", finish_reason: "stop", raw_output: "{}")
    end

    private

    def write_decision(path:, content:, message:)
      FakeDecision.new(
        intent: "change",
        message: message,
        actions: [
          {
            "id" => "write_#{path.gsub(/[^a-z0-9]/i, "_")}",
            "type" => "write_file",
            "args" => { "path" => path, "content" => content },
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

    def project_gap_decision
      FakeDecision.new(
        intent: "change",
        message: "build widget cli",
        actions: [],
        gaps: [
          {
            "id" => "gap-arch",
            "question" => "Do you prefer layered or flat structure?",
            "field" => "architecture_style",
            "inferred_value" => "layered",
            "resolved" => false,
            "priority" => 1
          }
        ],
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    def stop_asking_decision
      FakeDecision.new(
        intent: "change",
        message: "continue with inferred defaults",
        actions: [
          {
            "id" => "write_widget",
            "type" => "write_file",
            "args" => { "path" => "widget/README.md", "content" => "widget-ready\n" },
            "requires_confirmation" => false,
            "timeout_ms" => 10_000,
            "on_failure" => "abort"
          }
        ],
        gaps: [
          {
            "id" => "gap-arch",
            "question" => "Do you prefer layered or flat structure?",
            "field" => "architecture_style",
            "inferred_value" => "layered",
            "resolved" => false,
            "priority" => 1
          }
        ],
        control_intent: "cancel_clarification_only",
        control_scope: "task",
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    def control_decision(intent:, scope:, message:)
      FakeDecision.new(
        intent: "meta",
        message: message,
        actions: [],
        gaps: [],
        control_intent: intent,
        control_scope: scope,
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end
  end

  def with_test_root(name)
    Dir.mktmpdir("redwright-e2e-matrix-#{name}-") do |dir|
      yield dir
    end
  end

  def run_events(bootstrap:, events:, quality_runner: nil, blocked_retry_attempts: 1)
    project_store = Redwright::ProjectStore.new(bootstrap.db_path)
    workstream_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
    task_store = Redwright::TaskStore.new(bootstrap.db_path)
    chat_context_store = Redwright::ChatContextStore.new(bootstrap.db_path)
    clarification_session_store = Redwright::ClarificationSessionStore.new(bootstrap.db_path)

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
      projects_root: bootstrap.projects_root,
      clarification_session_store: clarification_session_store
    )

    prompt_loader = Object.new
    prompt_loader.define_singleton_method(:build) do |**_kwargs|
      { quality: { auto_validate: true, lint_command: nil, test_command: "bundle exec rake test" } }
    end

    ingress = Redwright::SimulatedIngressAdapter.new(events: events)
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: flow,
      telegram_client: ingress,
      out: StringIO.new,
      err: StringIO.new,
      context_resolver: resolver,
      chat_context_store: chat_context_store,
      clarification_session_store: clarification_session_store,
      blocked_retry_attempts: blocked_retry_attempts,
      intent_interpreter: MatrixInterpreter.new,
      quality_gate_runner: quality_runner,
      prompt_context_loader: prompt_loader
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

    {
      ingress: ingress,
      project_store: project_store,
      workstream_store: workstream_store,
      task_store: task_store,
      clarification_session_store: clarification_session_store
    }
  end

  def run_events_with_options(bootstrap:, events:, send_json_envelope: false)
    project_store = Redwright::ProjectStore.new(bootstrap.db_path)
    workstream_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
    task_store = Redwright::TaskStore.new(bootstrap.db_path)
    chat_context_store = Redwright::ChatContextStore.new(bootstrap.db_path)
    clarification_session_store = Redwright::ClarificationSessionStore.new(bootstrap.db_path)

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
      projects_root: bootstrap.projects_root,
      clarification_session_store: clarification_session_store
    )

    prompt_loader = Object.new
    prompt_loader.define_singleton_method(:build) do |**_kwargs|
      { quality: { auto_validate: false, lint_command: nil, test_command: nil } }
    end

    ingress = Redwright::SimulatedIngressAdapter.new(events: events)
    handler_out = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: flow,
      telegram_client: ingress,
      out: handler_out,
      err: StringIO.new,
      context_resolver: resolver,
      chat_context_store: chat_context_store,
      clarification_session_store: clarification_session_store,
      blocked_retry_attempts: 1,
      intent_interpreter: MatrixInterpreter.new,
      prompt_context_loader: prompt_loader,
      send_json_envelope: send_json_envelope
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

    {
      ingress: ingress,
      handler_out: handler_out.string
    }
  end

  def test_matrix_multilingual_stop_asking_continues_execution
    with_test_root("stop-asking") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_path = File.join(bootstrap.projects_root, "rw-control")
        FileUtils.mkdir_p(project_path)
        Redwright::ProjectStore.new(bootstrap.db_path).register(path: project_path, aliases: ["rw-control"])

        result = run_events(
          bootstrap: bootstrap,
          events: [
            Redwright::SimulatedIngressAdapter.event(external_message_id: 1, external_chat_id: 201, text: "rw-control build widget"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 2, external_chat_id: 201, text: "no more questions, continue")
          ]
        )

        assert(File.file?(File.join(project_path, "widget", "README.md")))
        assert_nil(result[:clarification_session_store].get_open(chat_id: 201))
      end
    end
  end

  def test_matrix_cancel_current_and_cancel_all_generate_control_transitions
    with_test_root("cancel-scopes") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        store = Redwright::ProjectStore.new(bootstrap.db_path)
        p1 = File.join(bootstrap.projects_root, "rw-cancel-a")
        p2 = File.join(bootstrap.projects_root, "rw-cancel-b")
        FileUtils.mkdir_p(p1)
        FileUtils.mkdir_p(p2)
        store.register(path: p1, aliases: ["rw-cancel-a"])
        store.register(path: p2, aliases: ["rw-cancel-b"])

        result = run_events(
          bootstrap: bootstrap,
          events: [
            Redwright::SimulatedIngressAdapter.event(external_message_id: 1, external_chat_id: 202, text: "rw-cancel-a start work"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 2, external_chat_id: 202, text: "rw-cancel-a cancel current task"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 3, external_chat_id: 203, text: "rw-cancel-b start work"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 4, external_chat_id: 203, text: "rw-cancel-b cancel all now")
          ]
        )

        tasks = result[:task_store].list
        stop_tasks = tasks.select { |t| t.description.start_with?("stop workstream:") }
        assert_operator(stop_tasks.size, :>=, 2)
      end
    end
  end

  def test_matrix_inferred_project_confirmation_and_followup_execution
    with_test_root("inferred-confirm") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        result = run_events(
          bootstrap: bootstrap,
          events: [
            Redwright::SimulatedIngressAdapter.event(external_message_id: 1, external_chat_id: 204, text: "Create tiny project named hello-cli and write starter"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 2, external_chat_id: 204, text: "yes"),
            Redwright::SimulatedIngressAdapter.event(external_message_id: 3, external_chat_id: 204, text: "write starter")
          ]
        )

        path = File.join(bootstrap.projects_root, "hello-cli", "starter", "README.md")
        assert(File.file?(path))
        combined = result[:ingress].sent_messages.map { |m| m[:text] }.join("\n")
        assert_match("I inferred project name 'hello-cli'", combined)
      end
    end
  end

  def test_matrix_non_convergent_loop_exits_with_max_attempts
    with_test_root("max-attempts") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_path = File.join(bootstrap.projects_root, "rw-nc")
        FileUtils.mkdir_p(project_path)
        Redwright::ProjectStore.new(bootstrap.db_path).register(path: project_path, aliases: ["rw-nc"])

        always_fail_quality = Object.new
        always_fail_quality.define_singleton_method(:run) do |**_kwargs|
          [Struct.new(:name, :status).new("test", "error")]
        end

        result = run_events(
          bootstrap: bootstrap,
          events: [
            Redwright::SimulatedIngressAdapter.event(external_message_id: 1, external_chat_id: 205, text: "rw-nc do work")
          ],
          quality_runner: always_fail_quality,
          blocked_retry_attempts: 2
        )

        combined = result[:ingress].sent_messages.map { |m| m[:text] }.join("\n")
        assert_match("terminal: max_attempts", combined)
        assert(File.file?(File.join(project_path, "runtime", "converged.txt")))
      end
    end
  end

  def test_matrix_emits_human_message_and_json_envelope_with_same_trace_id
    with_test_root("json-envelope-trace") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_path = File.join(bootstrap.projects_root, "rw-json")
        FileUtils.mkdir_p(project_path)
        Redwright::ProjectStore.new(bootstrap.db_path).register(path: project_path, aliases: ["rw-json"])

        result = run_events_with_options(
          bootstrap: bootstrap,
          send_json_envelope: true,
          events: [
            Redwright::SimulatedIngressAdapter.event(external_message_id: 1, external_chat_id: 206, text: "rw-json do work")
          ]
        )

        messages = result[:ingress].sent_messages.map { |m| m[:text] }
        assert_operator(messages.size, :>=, 2)
        human = messages.find { |m| m.include?("Trace: trc-") }
        json_msg = messages.find { |m| m.include?("```json") }
        refute_nil(human)
        refute_nil(json_msg)

        human_trace = human[/Trace:\s+(trc-[a-f0-9]+)/, 1]
        json_trace = json_msg[/\"trace_id\"\s*:\s*\"(trc-[a-f0-9]+)\"/, 1]
        refute_nil(human_trace)
        assert_equal(human_trace, json_trace)
        assert_match("telegram processed chat=206 task=", result[:handler_out])
      end
    end
  end
end
