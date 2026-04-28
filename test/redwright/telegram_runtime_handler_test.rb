# frozen_string_literal: true

require "tmpdir"
require "stringio"
require "json"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/project_store"
require "redwright/workstream_store"
require "redwright/task_store"
require "redwright/alignment_store"
require "redwright/plan_spec_store"
require "redwright/runtime_flow"
require "redwright/telegram_ingress"
require "redwright/telegram_runtime_handler"

class TelegramRuntimeHandlerTest < Minitest::Test
  FakeTelegramClient = Struct.new(:messages, :chat_actions) do
    def send_message(chat_id:, text:)
      self.messages ||= []
      self.messages << { chat_id: chat_id, text: text }
      { "ok" => true }
    end

    def send_chat_action(chat_id:, action: "typing")
      self.chat_actions ||= []
      self.chat_actions << { chat_id: chat_id, action: action }
      { "ok" => true }
    end
  end

  FakeDecision = Struct.new(:intent, :message, :actions, :gaps, :source, :finish_reason, :raw_output, keyword_init: true)
  FakeProject = Struct.new(:id, keyword_init: true)
  FakeWorkstream = Struct.new(:id, :state, keyword_init: true)
  FakeTask = Struct.new(:id, keyword_init: true)
  FakeActionResult = Struct.new(:action_id, :action_type, :status, :error_message, keyword_init: true)
  FakeResult = Struct.new(:project, :workstream, :task, :alignment, :action_results, keyword_init: true)
  FakeQualityCheck = Struct.new(:name, :status, keyword_init: true)

  def test_handle_materializes_runtime_action_and_sends_ack
    Dir.mktmpdir("redwright-telegram-handler-ok-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        ws_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        alignment_store = Redwright::AlignmentStore.new(bootstrap.db_path)
        spec_store = Redwright::PlanSpecStore.new(base_dir: dir)
        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: ws_store,
          task_store: task_store,
          alignment_store: alignment_store,
          plan_spec_store: spec_store
        )

        project = project_store.register(path: "#{dir}/apps/core", aliases: ["rw"])
        event = Redwright::TelegramEvent.new(update_id: 1, chat_id: 42, user_id: 9, username: "u", text: "do change")
        client = FakeTelegramClient.new([])
        out = StringIO.new
        err = StringIO.new
        handler = Redwright::TelegramRuntimeHandler.new(
          flow: flow,
          telegram_client: client,
          out: out,
          err: err,
          blocked_retry_attempts: 2
        )

        handler.handle(event)

        assert_equal("", err.string)
        assert_match("telegram processed chat=42 task=", out.string)
        rows = task_store.list
        assert_equal(1, rows.size)
        assert_equal("do change", rows.first.description)

        sent = client.messages.last
        assert_equal(42, sent[:chat_id])
        assert_match("Started task", sent[:text])
        assert_match("project #{project.id}", sent[:text])
        assert_match("state: executing", sent[:text])
        assert_match("Trace: trc-", sent[:text])
        assert_equal([{ chat_id: 42, action: "typing" }], client.chat_actions)
      end
    end
  end

  def test_handle_uses_interpreter_message_and_intent
    fake_flow = Object.new
    captured = {}
    fake_flow.define_singleton_method(:process) do |**kwargs|
      captured.merge!(kwargs)
      FakeResult.new(
        project: FakeProject.new(id: "project-1"),
        workstream: FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: FakeTask.new(id: "task-1"),
        alignment: nil,
        action_results: nil
      )
    end

    fake_interpreter = Object.new
    def fake_interpreter.interpret(text:, model:)
      raise "unexpected text" unless text == "hola"
      raise "unexpected model" unless model == "gpt-5-mini"

      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "meta",
        message: "show runtime status",
        source: "llm",
        finish_reason: "stop",
        raw_output: "{\"intent\":\"meta\",\"message\":\"show runtime status\"}"
      )
    end

    client = FakeTelegramClient.new([])
    out = StringIO.new
    err = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: err,
      blocked_retry_attempts: 1,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 3, chat_id: 9, user_id: nil, username: nil, text: "hola"))

    assert_equal("meta", captured[:intent])
    assert_equal("show runtime status", captured[:message])
    assert_equal("", err.string)
    assert_match("telegram processed chat=9 task=task-1", out.string)
  end

  def test_handle_keeps_typing_while_processing_longer_than_interval
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      sleep(0.06)
      FakeResult.new(
        project: FakeProject.new(id: "project-2"),
        workstream: FakeWorkstream.new(id: "ws-2", state: "executing"),
        task: FakeTask.new(id: "task-2"),
        alignment: nil,
        action_results: nil
      )
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      raise "unexpected text" unless text == "hola"
      raise "unexpected model" unless model == "gpt-5-mini"

      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: "do thing",
        source: "llm",
        finish_reason: "stop",
        raw_output: "{\"intent\":\"change\",\"message\":\"do thing\"}"
      )
    end

    client = FakeTelegramClient.new([], [])
    out = StringIO.new
    err = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: err,
      blocked_retry_attempts: 1,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter,
      typing_interval_seconds: 0.02
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 4, chat_id: 55, user_id: nil, username: nil, text: "hola"))

    assert_operator(client.chat_actions.length, :>=, 2)
    assert_equal("", err.string)
    assert_match("telegram processed chat=55 task=task-2", out.string)
  end

  def test_handle_sends_error_message_when_flow_fails
    fake_flow = Object.new
    def fake_flow.process(**_kwargs)
      raise ArgumentError, "project not found"
    end

    client = FakeTelegramClient.new([])
    out = StringIO.new
    err = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: err,
      blocked_retry_attempts: 1
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 2, chat_id: 7, user_id: nil, username: nil, text: "hello"))

    assert_equal("", out.string)
    assert_match("project not found", err.string)
    assert_equal(1, client.messages.size)
    assert_equal(7, client.messages.first[:chat_id])
    assert_match("Error: project not found", client.messages.first[:text])
    assert_match("Trace: trc-", client.messages.first[:text])
  end

  def test_handle_sends_clarify_and_skips_flow_when_context_is_ambiguous
    fake_flow = Object.new
    def fake_flow.process(**_kwargs)
      raise "flow should not run on clarify"
    end

    fake_resolver = Object.new
    def fake_resolver.resolve(chat_id:, text:)
      raise "unexpected chat_id" unless chat_id == 88
      raise "unexpected text" unless text == "continue"

      Redwright::TelegramContextResolver::Resolution.new(
        resolved: false,
        project_ref: nil,
        workstream_id: nil,
        question: "Please specify project."
      )
    end

    client = FakeTelegramClient.new([])
    out = StringIO.new
    err = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: err,
      context_resolver: fake_resolver,
      blocked_retry_attempts: 1
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 2, chat_id: 88, user_id: nil, username: nil, text: "continue"))

    assert_equal("", err.string)
    assert_match("telegram clarify chat=88", out.string)
    assert_equal(1, client.messages.size)
    assert_match("Please specify project.", client.messages.first[:text])
    assert_match("Trace: trc-", client.messages.first[:text])
  end

  def test_handle_sends_single_high_value_clarify_for_unresolved_gaps
    fake_flow = Object.new
    def fake_flow.process(**_kwargs)
      raise "flow should not run when unresolved gaps exist"
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: "normalized",
        actions: [],
        gaps: [
          { "id" => "g2", "question" => "What branch strategy should be used?", "field" => "branch_strategy", "inferred_value" => "", "resolved" => false, "priority" => 3 },
          { "id" => "g1", "question" => "What is the project name?", "field" => "project_name", "inferred_value" => "hello-cli", "resolved" => false, "priority" => 1 }
        ],
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    client = FakeTelegramClient.new([])
    out = StringIO.new
    err = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: err,
      blocked_retry_attempts: 1,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 2, chat_id: 66, user_id: nil, username: nil, text: "build app"))

    assert_equal("", err.string)
    assert_match("telegram clarify chat=66", out.string)
    assert_equal(1, client.messages.size)
    assert_match("What is the project name?", client.messages.first[:text])
  end

  def test_handle_routes_pause_command_to_control_flow
    fake_flow = Object.new
    captured = {}
    fake_flow.define_singleton_method(:control) do |**kwargs|
      captured.merge!(kwargs)
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "suspended"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-pause"),
        alignment: nil,
        action_results: []
      )
    end

    fake_resolver = Object.new
    fake_resolver.define_singleton_method(:resolve) do |chat_id:, text:|
      Redwright::TelegramContextResolver::Resolution.new(
        resolved: true,
        project_ref: "rw",
        project_path: "/tmp/rw",
        workstream_id: "ws-1",
        question: nil
      )
    end

    client = FakeTelegramClient.new([])
    out = StringIO.new
    err = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: err,
      context_resolver: fake_resolver,
      blocked_retry_attempts: 1
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 33, chat_id: 88, user_id: nil, username: nil, text: "pause for now"))

    assert_equal("pause", captured[:command])
    assert_equal("rw", captured[:project_ref])
    assert_equal("ws-1", captured[:workstream_id])
    assert_equal("", err.string)
    assert_match("telegram control chat=88 command=pause task=task-pause", out.string)
  end

  def test_handle_includes_execution_summary_and_passes_actions_to_flow
    fake_flow = Object.new
    captured = {}
    fake_flow.define_singleton_method(:process) do |**kwargs|
      captured.merge!(kwargs)
      FakeResult.new(
        project: FakeProject.new(id: "project-x"),
        workstream: FakeWorkstream.new(id: "ws-x", state: "executing"),
        task: FakeTask.new(id: "task-x"),
        alignment: nil,
        action_results: [
          FakeActionResult.new(action_id: "a1", status: "ok"),
          FakeActionResult.new(action_id: "a2", status: "error")
        ]
      )
    end

    fake_interpreter = Object.new
    def fake_interpreter.interpret(text:, model:)
      raise "unexpected text" unless text == "do stuff"
      raise "unexpected model" unless model == "gpt-5-mini"

      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: "do stuff normalized",
        actions: [
          {
            "id" => "a1",
            "type" => "list_files",
            "args" => {},
            "requires_confirmation" => false,
            "timeout_ms" => 1000,
            "on_failure" => "continue"
          }
        ],
        source: "llm",
        finish_reason: "stop",
        raw_output: "{\"intent\":\"change\",\"message\":\"do stuff normalized\",\"actions\":[]}"
      )
    end

    client = FakeTelegramClient.new([])
    out = StringIO.new
    err = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: err,
      blocked_retry_attempts: 1,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 9, chat_id: 9, user_id: nil, username: nil, text: "do stuff"))

    assert_equal("change", captured[:intent])
    assert_equal("do stuff normalized", captured[:message])
    assert_equal(1, captured[:actions].size)

    assert_match("Started task task-x in project project-x.", client.messages.last[:text])
    assert_match("Actions: 1/2 succeeded, 1 failed.", client.messages.last[:text])
    assert_match("telegram processed chat=9 task=task-x", out.string)
    assert_equal("", err.string)
  end

  def test_handle_sends_json_envelope_in_code_block_when_enabled
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      FakeResult.new(
        project: FakeProject.new(id: "project-z"),
        workstream: FakeWorkstream.new(id: "ws-z", state: "executing"),
        task: FakeTask.new(id: "task-z"),
        alignment: nil,
        action_results: nil
      )
    end

    client = FakeTelegramClient.new([])
    out = StringIO.new
    err = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: err,
      blocked_retry_attempts: 1,
      send_json_envelope: true
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 10, chat_id: 11, user_id: nil, username: nil, text: "do stuff"))

    assert_equal(2, client.messages.size)
    assert_match("Started task task-z in project project-z.", client.messages.first[:text])
    assert_match("```json", client.messages.last[:text])
    assert_match("```", client.messages.last[:text])
    json_text = client.messages.last[:text].sub(/\A```json\n/, "").sub(/\n```\z/, "")
    payload = JSON.parse(json_text)
    assert_equal("ok", payload["status"])
    assert_equal("project-z", payload.dig("runtime", "project_id"))
    assert_equal("ws-z", payload.dig("runtime", "workstream_id"))
    assert_equal("task-z", payload.dig("runtime", "task_id"))
    assert_equal("success", payload.dig("runtime", "terminal_reason"))
  end

  def test_handle_passes_dynamic_prompt_context_to_interpreter_when_supported
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      FakeResult.new(
        project: FakeProject.new(id: "project-c"),
        workstream: FakeWorkstream.new(id: "ws-c", state: "executing"),
        task: FakeTask.new(id: "task-c"),
        alignment: nil,
        action_results: nil
      )
    end

    fake_resolver = Object.new
    fake_resolver.define_singleton_method(:resolve) do |chat_id:, text:|
      Redwright::TelegramContextResolver::Resolution.new(
        resolved: true,
        project_ref: "project-c",
        project_path: "/tmp/project-c",
        workstream_id: nil,
        question: nil
      )
    end

    loader = Object.new
    loader.define_singleton_method(:build) do |project_path:|
      {
        project_context: "Project path: #{project_path}",
        architecture_context: "Conventions: Keep docs in English"
      }
    end

    fake_interpreter = Object.new
    captured = {}
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:, project_context:, architecture_context:|
      captured[:project_context] = project_context
      captured[:architecture_context] = architecture_context
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: "do thing",
        actions: [],
        source: "llm",
        finish_reason: "stop",
        raw_output: "{\"intent\":\"change\",\"message\":\"do thing\",\"actions\":[]}"
      )
    end
    fake_interpreter.define_singleton_method(:system_prompt) do |project_context:, architecture_context:|
      "PROMPT #{project_context} #{architecture_context}"
    end

    client = FakeTelegramClient.new([])
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      context_resolver: fake_resolver,
      blocked_retry_attempts: 1,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter,
      prompt_context_loader: loader
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 11, chat_id: 5, user_id: nil, username: nil, text: "do thing"))

    assert_equal("Project path: /tmp/project-c", captured[:project_context])
    assert_equal("Conventions: Keep docs in English", captured[:architecture_context])
  end

  def test_handle_rejects_invalid_planner_fallback_before_execution_and_persists_reason
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      raise "flow should not execute when planner output is invalid"
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:, **_kwargs|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: text,
        actions: [],
        source: "fallback",
        finish_reason: "invalid_payload:action_0_type_not_allowed:write_files",
        raw_output: "{\"intent\":\"change\",\"actions\":[{\"type\":\"write_files\"}]}"
      )
    end
    fake_interpreter.define_singleton_method(:system_prompt) { |**_kwargs| "prompt" }

    persisted = []
    fake_rejections = Object.new
    fake_rejections.define_singleton_method(:create) do |**kwargs|
      persisted << kwargs
      Struct.new(:id).new("rej-1")
    end

    client = FakeTelegramClient.new([])
    out = StringIO.new
    err = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: err,
      blocked_retry_attempts: 1,
      intent_interpreter: fake_interpreter,
      planner_rejection_store: fake_rejections
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 12, chat_id: 12, user_id: nil, username: nil, text: "do stuff"))

    assert_equal("", err.string)
    assert_equal(1, persisted.size)
    assert_equal("invalid_payload:action_0_type_not_allowed:write_files", persisted.first[:reason])
    assert_match("Planner output was rejected before execution.", client.messages.last[:text])
    assert_match("No actions were executed for this turn.", client.messages.last[:text])
    assert_match("telegram planner_reject chat=12", out.string)
  end

  def test_handle_reports_quality_gate_summary_when_enabled_by_context
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      FakeResult.new(
        project: FakeProject.new(id: "project-q"),
        workstream: FakeWorkstream.new(id: "ws-q", state: "executing"),
        task: FakeTask.new(id: "task-q"),
        alignment: nil,
        action_results: [
          FakeActionResult.new(action_id: "a1", status: "ok")
        ]
      )
    end

    fake_resolver = Object.new
    fake_resolver.define_singleton_method(:resolve) do |**_kwargs|
      Redwright::TelegramContextResolver::Resolution.new(
        resolved: true,
        project_ref: "project-q",
        project_path: "/tmp/project-q",
        workstream_id: nil,
        question: nil
      )
    end

    loader = Object.new
    loader.define_singleton_method(:build) do |**_kwargs|
      {
        project_context: "project",
        architecture_context: "architecture",
        quality: {
          auto_validate: true,
          lint_command: "lint",
          test_command: "test"
        }
      }
    end

    quality_runner = Object.new
    quality_runner.define_singleton_method(:run) do |**_kwargs|
      [
        Struct.new(:name, :status).new("lint", "ok"),
        Struct.new(:name, :status).new("test", "error")
      ]
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |**_kwargs|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: "do thing",
        actions: [],
        source: "llm",
        finish_reason: "stop",
        raw_output: "{\"intent\":\"change\",\"message\":\"do thing\",\"actions\":[]}"
      )
    end
    fake_interpreter.define_singleton_method(:system_prompt) { |**_kwargs| "prompt" }

    client = FakeTelegramClient.new([])
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      context_resolver: fake_resolver,
      blocked_retry_attempts: 1,
      intent_interpreter: fake_interpreter,
      prompt_context_loader: loader,
      quality_gate_runner: quality_runner
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 13, chat_id: 13, user_id: nil, username: nil, text: "do thing"))

    assert_match("Quality checks: 1/2 passed, 1 failed.", client.messages.last[:text])
  end

  def test_handle_retries_change_turn_when_quality_fails_then_succeeds
    flow_calls = 0
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      flow_calls += 1
      FakeResult.new(
        project: FakeProject.new(id: "project-r"),
        workstream: FakeWorkstream.new(id: "ws-r", state: "executing"),
        task: FakeTask.new(id: "task-r"),
        alignment: nil,
        action_results: [FakeActionResult.new(action_id: "a1", status: "ok")]
      )
    end

    interp_calls = []
    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      interp_calls << text
      raise "unexpected model" unless model == "gpt-5-mini"

      FakeDecision.new(
        intent: "change",
        message: "apply change",
        actions: [],
        source: "llm",
        finish_reason: "stop",
        raw_output: "{\"intent\":\"change\",\"message\":\"apply change\",\"actions\":[]}"
      )
    end

    quality_runs = 0
    fake_quality_runner = Object.new
    fake_quality_runner.define_singleton_method(:run) do |project_path:, lint_command:, test_command:|
      quality_runs += 1
      if quality_runs == 1
        [FakeQualityCheck.new(name: "test", status: "error")]
      else
        [FakeQualityCheck.new(name: "test", status: "ok")]
      end
    end

    fake_resolver = Object.new
    fake_resolver.define_singleton_method(:resolve) do |chat_id:, text:|
      Redwright::TelegramContextResolver::Resolution.new(
        resolved: true,
        project_ref: "p1",
        project_path: "/tmp/project",
        workstream_id: nil,
        question: nil
      )
    end

    fake_prompt_loader = Object.new
    fake_prompt_loader.define_singleton_method(:build) do |project_path:|
      {
        project_context: nil,
        architecture_context: nil,
        workspace_context: nil,
        quality: { auto_validate: true, lint_command: nil, test_command: "bundle exec rake test" }
      }
    end

    client = FakeTelegramClient.new([])
    out = StringIO.new
    err = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: err,
      context_resolver: fake_resolver,
      blocked_retry_attempts: 2,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter,
      prompt_context_loader: fake_prompt_loader,
      quality_gate_runner: fake_quality_runner
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 21, chat_id: 9, user_id: nil, username: nil, text: "do work"))

    assert_equal(2, quality_runs)
    assert_equal(2, flow_calls)
    assert_equal(2, interp_calls.size)
    assert_match("Validation failed after execution.", interp_calls.last)
    assert_match("Attempts: 2 (terminal: success).", client.messages.last[:text])
    assert_equal("", err.string)
  end

  def test_handle_stops_at_max_attempts_when_quality_keeps_failing
    flow_calls = 0
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      flow_calls += 1
      FakeResult.new(
        project: FakeProject.new(id: "project-f"),
        workstream: FakeWorkstream.new(id: "ws-f", state: "executing"),
        task: FakeTask.new(id: "task-f"),
        alignment: nil,
        action_results: [FakeActionResult.new(action_id: "a1", status: "ok")]
      )
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      FakeDecision.new(
        intent: "change",
        message: "apply change",
        actions: [],
        source: "llm",
        finish_reason: "stop",
        raw_output: "{\"intent\":\"change\",\"message\":\"apply change\",\"actions\":[]}"
      )
    end

    fake_quality_runner = Object.new
    fake_quality_runner.define_singleton_method(:run) do |project_path:, lint_command:, test_command:|
      [FakeQualityCheck.new(name: "test", status: "error")]
    end

    fake_resolver = Object.new
    fake_resolver.define_singleton_method(:resolve) do |chat_id:, text:|
      Redwright::TelegramContextResolver::Resolution.new(
        resolved: true,
        project_ref: "p1",
        project_path: "/tmp/project",
        workstream_id: nil,
        question: nil
      )
    end

    fake_prompt_loader = Object.new
    fake_prompt_loader.define_singleton_method(:build) do |project_path:|
      {
        project_context: nil,
        architecture_context: nil,
        workspace_context: nil,
        quality: { auto_validate: true, lint_command: nil, test_command: "bundle exec rake test" }
      }
    end

    client = FakeTelegramClient.new([])
    out = StringIO.new
    err = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: err,
      context_resolver: fake_resolver,
      blocked_retry_attempts: 2,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter,
      prompt_context_loader: fake_prompt_loader,
      quality_gate_runner: fake_quality_runner
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 22, chat_id: 9, user_id: nil, username: nil, text: "do work"))

    assert_equal(2, flow_calls)
    assert_match("Attempts: 2 (terminal: max_attempts).", client.messages.last[:text])
    assert_equal("", err.string)
  end

  def test_handle_includes_actionable_confirmation_hint_when_commit_is_blocked
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      FakeResult.new(
        project: FakeProject.new(id: "project-cb"),
        workstream: FakeWorkstream.new(id: "ws-cb", state: "executing"),
        task: FakeTask.new(id: "task-cb"),
        alignment: nil,
        action_results: [
          FakeActionResult.new(action_id: "git_commit_1", action_type: "git_commit", status: "error", error_message: "confirmation_required")
        ]
      )
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      FakeDecision.new(
        intent: "change",
        message: "commit changes",
        actions: [],
        source: "llm",
        finish_reason: "stop",
        raw_output: "{\"intent\":\"change\",\"message\":\"commit changes\",\"actions\":[]}"
      )
    end

    client = FakeTelegramClient.new([])
    out = StringIO.new
    err = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: err,
      blocked_retry_attempts: 1,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 23, chat_id: 9, user_id: nil, username: nil, text: "commit this"))

    assert_match("Commit/push actions were blocked by confirmation policy", client.messages.last[:text])
    assert_match("git_commit_1", client.messages.last[:text])
    assert_equal("", err.string)
  end
end
