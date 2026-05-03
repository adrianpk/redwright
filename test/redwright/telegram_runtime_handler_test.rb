# frozen_string_literal: true

require "tmpdir"
require "stringio"
require "json"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/bootstrap"
require "redwright/ingress_port"
require "redwright/project_store"
require "redwright/workstream_store"
require "redwright/task_store"
require "redwright/alignment_store"
require "redwright/plan_spec_store"
require "redwright/runtime_flow"
require "redwright/server_runtime_dispatcher"
require "redwright/telegram_ingress"
require "redwright/telegram_runtime_handler"
require "redwright/telegram_project_setup_adapter"

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

  FakeDecision = Struct.new(
    :intent,
    :message,
    :actions,
    :gaps,
    :control_intent,
    :control_scope,
    :operational_intent,
    :operational_scope,
    :operational_args,
    :operational_requires_project,
    :operational_requires_confirmation,
    :skill_requested,
    :skill_mode,
    :source,
    :finish_reason,
    :raw_output,
    keyword_init: true
  )
  FakeProject = Struct.new(:id, keyword_init: true)
  FakeWorkstream = Struct.new(:id, :state, keyword_init: true)
  FakeTask = Struct.new(:id, keyword_init: true)
  FakeActionResult = Struct.new(:action_id, :action_type, :status, :error_message, keyword_init: true)
  FakeResult = Struct.new(:project, :workstream, :task, :alignment, :action_results, keyword_init: true)
  FakeQualityCheck = Struct.new(:name, :status, keyword_init: true)
  FakeApiResponse = Struct.new(:body, keyword_init: true)

  class FakeProjectSetupClient
    attr_reader :calls

    def initialize
      @calls = []
    end

    def command(name:, payload:, actor_identifier:, request_id:)
      @calls << {
        type: "command",
        name: name,
        payload: payload,
        actor_identifier: actor_identifier,
        request_id: request_id
      }
      body = if name == "StartProjectSetup"
               slot = if payload["project_name"].to_s.empty?
                        "project_name"
                      elsif payload["description"].to_s.empty?
                        "description"
                      else
                        "project_type"
                      end
               {
                 "status" => "ok",
                 "summary" => "Project setup started.",
                 "session_id" => 101,
                 "state" => "collecting_context",
                 "next_prompt" => nil,
                 "data" => {
                   "next_prompt_intent" => {
                     "kind" => "setup_slot_question",
                     "slot" => slot,
                     "locale" => "auto",
                     "llm_required" => true
                   }
                 }
               }
             elsif name == "AdvanceProjectSetup"
               {
                 "status" => "ok",
                 "summary" => "Project setup context updated.",
                 "session_id" => 101,
                 "state" => "collecting_context",
                 "next_prompt" => nil,
                 "data" => {
                   "next_prompt_intent" => {
                     "kind" => "setup_slot_question",
                     "slot" => "project_type",
                     "locale" => "auto",
                     "llm_required" => true
                   }
                 }
               }
             else
               raise "unexpected command #{name}"
             end
      FakeApiResponse.new(body: body)
    end

    def query(name:, payload:, actor_identifier:, request_id:)
      @calls << {
        type: "query",
        name: name,
        payload: payload,
        actor_identifier: actor_identifier,
        request_id: request_id
      }
      FakeApiResponse.new(body: { "status" => "ok", "summary" => "ok" })
    end
  end

  def build_fake_clarification_store(cancellations)
    store = Object.new
    store.define_singleton_method(:get_open) do |**_kwargs|
      nil
    end
    store.define_singleton_method(:open_planner_gap) do |**_kwargs|
      nil
    end
    store.define_singleton_method(:advance) do |**_kwargs|
      nil
    end
    store.define_singleton_method(:cancel_open) do |**kwargs|
      cancellations << kwargs
    end
    store
  end

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

  def test_handle_routes_operational_slash_through_dispatcher_without_llm
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      raise "flow.process should not run for deterministic operational slash"
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |**_kwargs|
      raise "interpreter should not run for deterministic operational slash"
    end

    fake_dispatcher = Object.new
    captured = nil
    fake_dispatcher.define_singleton_method(:call) do |request|
      captured = request
      {
        "status" => "ok",
        "project_id" => "project-ops",
        "workstream_id" => "ws-ops",
        "task_id" => "task-ops",
        "state" => "executing",
        "terminal_reason" => "executing"
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
      blocked_retry_attempts: 1,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter,
      operational_dispatcher: fake_dispatcher
    )

    handler.handle(
      Redwright::TelegramEvent.new(
        update_id: 301,
        chat_id: 77,
        user_id: nil,
        username: nil,
        text: "/project switch alpha"
      )
    )

    refute_nil(captured)
    assert_equal("send", captured["type"])
    assert_equal("telegram-77", captured["session_id"])
    assert_equal("/project switch alpha", captured["payload"]["message"])
    assert_match("telegram operational chat=77 command=project_switch task=task-ops", out.string)
    assert_equal("", err.string)
  end

  def test_handle_direct_control_slash_bypasses_llm_and_uses_flow_control
    captured = {}
    fake_flow = Object.new
    fake_flow.define_singleton_method(:control) do |**kwargs|
      captured.merge!(kwargs)
      FakeResult.new(
        project: FakeProject.new(id: "project-ctrl"),
        workstream: FakeWorkstream.new(id: "ws-ctrl", state: "paused"),
        task: FakeTask.new(id: "task-ctrl"),
        alignment: nil,
        action_results: nil
      )
    end
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      raise "flow.process should not run for direct control slash"
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |**_kwargs|
      raise "interpreter should not run for direct control slash"
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

    handler.handle(
      Redwright::TelegramEvent.new(
        update_id: 402,
        chat_id: 92,
        user_id: nil,
        username: nil,
        text: "/pause"
      )
    )

    assert_equal("pause", captured[:command])
    assert_equal("/pause", captured[:reason])
    assert_match("telegram control chat=92 command=pause task=task-ctrl", out.string)
    assert_equal("", err.string)
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
        actions: [
          { "id" => "a1", "type" => "write_file", "args" => { "path" => "README.md", "content" => "x" }, "requires_confirmation" => false, "timeout_ms" => 1000, "on_failure" => "abort" }
        ],
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

  def test_handle_defers_optional_gap_and_executes_change_turn
    fake_flow = Object.new
    captured = {}
    fake_flow.define_singleton_method(:process) do |**kwargs|
      captured.merge!(kwargs)
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-1"),
        alignment: nil,
        action_results: []
      )
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: "build app",
        actions: [
          { "id" => "a1", "type" => "write_file", "args" => { "path" => "README.md", "content" => "x" }, "requires_confirmation" => false, "timeout_ms" => 1000, "on_failure" => "abort" }
        ],
        gaps: [
          { "id" => "g1", "question" => "Architecture style?", "field" => "architecture_style", "inferred_value" => "clean", "resolved" => false, "priority" => 1 }
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

    handler.handle(Redwright::TelegramEvent.new(update_id: 77, chat_id: 77, user_id: nil, username: nil, text: "build app"))

    assert_equal("change", captured[:intent])
    refute_match("telegram clarify chat=77", out.string)
    assert_match("telegram processed chat=77 task=task-1", out.string)
  end

  def test_handle_does_not_send_json_envelope_when_disabled
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      FakeResult.new(
        project: FakeProject.new(id: "project-no-json"),
        workstream: FakeWorkstream.new(id: "ws-no-json", state: "executing"),
        task: FakeTask.new(id: "task-no-json"),
        alignment: nil,
        action_results: nil
      )
    end

    client = FakeTelegramClient.new([])
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      blocked_retry_attempts: 1,
      send_json_envelope: false
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 99, chat_id: 33, user_id: nil, username: nil, text: "do stuff"))

    assert_equal(1, client.messages.size)
    refute_match(/```json/, client.messages.first[:text])
    assert_match("Started task task-no-json in project project-no-json.", client.messages.first[:text])
  end

  def test_handle_cancels_task_clarification_and_processes_when_semantic_intent_is_cancel_clarification_only
    fake_flow = Object.new
    captured = {}
    fake_flow.define_singleton_method(:process) do |**kwargs|
      captured.merge!(kwargs)
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-after-cancel-clarify"),
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
    cancellations = []
    fake_clarification_store = build_fake_clarification_store(cancellations)
    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: "continue with current task",
        actions: [],
        gaps: [{ "id" => "g1", "question" => "Which Ruby version?", "field" => "ruby_version", "resolved" => false, "priority" => 1 }],
        control_intent: "cancel_clarification_only",
        control_scope: "task",
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: err,
      context_resolver: fake_resolver,
      clarification_session_store: fake_clarification_store,
      intent_interpreter: fake_interpreter,
      blocked_retry_attempts: 1
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 33, chat_id: 88, user_id: nil, username: nil, text: "pause for now"))

    assert_equal("change", captured[:intent])
    assert_equal("rw", captured[:project_ref])
    assert_equal("ws-1", captured[:workstream_id])
    assert_equal([{ chat_id: 88, workstream_id: "ws-1" }], cancellations)
    assert_equal("", err.string)
    assert_match("telegram processed chat=88 task=task-after-cancel-clarify", out.string)
  end

  def test_handle_routes_semantic_stop_control_to_flow
    fake_flow = Object.new
    captured = {}
    fake_flow.define_singleton_method(:control) do |**kwargs|
      captured.merge!(kwargs)
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "blocked"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-stop"),
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
    cancellations = []
    fake_clarification_store = build_fake_clarification_store(cancellations)
    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "meta",
        message: "cancel current task",
        actions: [],
        gaps: [],
        control_intent: "cancel_task",
        control_scope: "task",
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      context_resolver: fake_resolver,
      clarification_session_store: fake_clarification_store,
      intent_interpreter: fake_interpreter,
      blocked_retry_attempts: 1
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 34, chat_id: 89, user_id: nil, username: nil, text: "cancela todo"))

    assert_equal("stop", captured[:command])
    assert_equal("rw", captured[:project_ref])
    assert_equal("ws-1", captured[:workstream_id])
    assert_equal([{ chat_id: 89 }], cancellations)
  end

  def test_handle_routes_semantic_resume_control_to_flow
    fake_flow = Object.new
    captured = {}
    fake_flow.define_singleton_method(:control) do |**kwargs|
      captured.merge!(kwargs)
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-resume"),
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
    cancellations = []
    fake_clarification_store = build_fake_clarification_store(cancellations)
    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "meta",
        message: "proceed with current context",
        actions: [],
        gaps: [],
        control_intent: "proceed_with_current_context",
        control_scope: "task",
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      context_resolver: fake_resolver,
      clarification_session_store: fake_clarification_store,
      intent_interpreter: fake_interpreter,
      blocked_retry_attempts: 1
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 35, chat_id: 90, user_id: nil, username: nil, text: "continua con lo que tengas"))

    assert_equal("resume", captured[:command])
    assert_equal("rw", captured[:project_ref])
    assert_equal("ws-1", captured[:workstream_id])
    assert_equal([{ chat_id: 90, workstream_id: "ws-1" }, { chat_id: 90, workstream_id: "ws-1" }], cancellations)
  end

  def test_handle_does_not_route_resume_control_when_intent_is_change
    fake_flow = Object.new
    captured_process = {}
    control_calls = 0
    fake_flow.define_singleton_method(:process) do |**kwargs|
      captured_process.merge!(kwargs)
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-change"),
        alignment: nil,
        action_results: []
      )
    end
    fake_flow.define_singleton_method(:control) do |**_kwargs|
      control_calls += 1
      raise "unexpected control call"
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
    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: "continue implementation and apply pending changes",
        actions: [],
        gaps: [],
        control_intent: "proceed_with_current_context",
        control_scope: "task",
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      context_resolver: fake_resolver,
      blocked_retry_attempts: 1,
      intent_interpreter: fake_interpreter
    )

    handler.handle(
      Redwright::TelegramEvent.new(
        update_id: 350,
        chat_id: 901,
        user_id: nil,
        username: nil,
        text: "para con las preguntas y continua implementando"
      )
    )

    assert_equal(0, control_calls)
    assert_equal("rw", captured_process[:project_ref])
    assert_equal("change", captured_process[:intent])
    assert_equal("continue implementation and apply pending changes", captured_process[:message])
  end

  def test_handle_routes_pause_slash_directly_to_flow_control
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
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      raise "process should not run for /pause"
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

    handler.handle(Redwright::TelegramEvent.new(update_id: 88, chat_id: 44, user_id: nil, username: nil, text: "/pause"))

    assert_equal("pause", captured[:command])
    assert_match("telegram control chat=44 command=pause", out.string)
    assert_equal("", err.string)
  end

  def test_handle_routes_task_pause_resume_cancel_slash_to_flow_control
    fake_flow = Object.new
    commands = []
    fake_flow.define_singleton_method(:control) do |**kwargs|
      commands << kwargs[:command]
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-control"),
        alignment: nil,
        action_results: []
      )
    end
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      raise "process should not run for /task pause|resume|cancel"
    end

    client = FakeTelegramClient.new([])
    out = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: StringIO.new,
      blocked_retry_attempts: 1
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 801, chat_id: 45, user_id: nil, username: nil, text: "/task pause"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 802, chat_id: 45, user_id: nil, username: nil, text: "/task resume"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 803, chat_id: 45, user_id: nil, username: nil, text: "/task cancel"))

    assert_equal(%w[pause resume stop], commands)
    assert_match("telegram control chat=45 command=pause", out.string)
    assert_match("telegram control chat=45 command=resume", out.string)
    assert_match("telegram control chat=45 command=stop", out.string)
  end

  def test_handle_routes_operational_intent_controls_to_flow_control
    fake_flow = Object.new
    commands = []
    fake_flow.define_singleton_method(:control) do |**kwargs|
      commands << kwargs[:command]
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-operational-control"),
        alignment: nil,
        action_results: []
      )
    end
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      raise "process should not run for operational control intents"
    end

    intents = %w[task_pause task_resume task_cancel plan_continue plan_stop_and_apply]
    fake_interpreter = Object.new
    idx = 0
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      intent = intents[idx]
      idx += 1
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "meta",
        message: "operational #{intent}",
        actions: [],
        gaps: [],
        control_intent: "none",
        control_scope: "none",
        operational_intent: intent,
        operational_scope: "runtime",
        operational_args: {},
        operational_requires_project: false,
        operational_requires_confirmation: false,
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: FakeTelegramClient.new([]),
      out: StringIO.new,
      err: StringIO.new,
      blocked_retry_attempts: 1,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter
    )

    intents.each_with_index do |_intent, i|
      handler.handle(Redwright::TelegramEvent.new(update_id: 820 + i, chat_id: 71, user_id: nil, username: nil, text: "meta op #{i}"))
    end

    assert_equal(%w[pause resume stop resume resume], commands)
  end

  def test_handle_infers_multilingual_control_when_planner_returns_meta_without_control_intent
    fake_flow = Object.new
    commands = []
    fake_flow.define_singleton_method(:control) do |**kwargs|
      commands << kwargs[:command]
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-inferred-control"),
        alignment: nil,
        action_results: []
      )
    end
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      raise "process should not run for inferred control commands"
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "meta",
        message: "meta drift",
        actions: [],
        gaps: [],
        control_intent: "none",
        control_scope: "none",
        operational_intent: "none",
        operational_scope: "none",
        operational_args: {},
        operational_requires_project: false,
        operational_requires_confirmation: false,
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: FakeTelegramClient.new([]),
      out: StringIO.new,
      err: StringIO.new,
      blocked_retry_attempts: 1,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 830, chat_id: 72, user_id: nil, username: nil, text: "pausa"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 831, chat_id: 72, user_id: nil, username: nil, text: "continua"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 832, chat_id: 72, user_id: nil, username: nil, text: "cancelar"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 833, chat_id: 72, user_id: nil, username: nil, text: "continue"))

    assert_equal(%w[pause resume stop resume], commands)
  end

  def test_handle_rewrites_continue_slash_to_planner_hint
    fake_flow = Object.new
    captured = {}
    fake_flow.define_singleton_method(:process) do |**kwargs|
      captured.merge!(kwargs)
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-continue"),
        alignment: nil,
        action_results: []
      )
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      raise "continue slash hint not propagated" unless text.include?("Continue with current context")

      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: "continue with current assumptions",
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

    handler.handle(Redwright::TelegramEvent.new(update_id: 89, chat_id: 45, user_id: nil, username: nil, text: "/continue"))

    assert_equal("continue with current assumptions", captured[:message])
    assert_equal("", err.string)
    assert_match("telegram processed chat=45 task=task-continue", out.string)
  end

  def test_handle_rewrites_project_and_skill_slash_to_explicit_planner_hints
    fake_flow = Object.new
    captured = []
    fake_flow.define_singleton_method(:process) do |**kwargs|
      captured << kwargs
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-hint"),
        alignment: nil,
        action_results: []
      )
    end

    seen = []
    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      seen << text
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: text,
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

    handler.handle(Redwright::TelegramEvent.new(update_id: 90, chat_id: 46, user_id: nil, username: nil, text: "/project switch rw"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 91, chat_id: 46, user_id: nil, username: nil, text: "/skill grill-me"))

    assert(seen.any? { |t| t.include?("Switch active project to rw") })
    assert(seen.any? { |t| t.include?("Activate skill 'grill-me' in explicit mode") })
    assert_match("telegram skill chat=46 name=grill-me mode=explicit confidence=1.0 reason=explicit_slash_skill", out.string)
    assert_equal("", err.string)
  end

  def test_handle_clarifies_on_project_new_without_name_and_does_not_run_flow
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      raise "flow should not run when /project new is missing a name"
    end

    client = FakeTelegramClient.new([])
    out = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: StringIO.new,
      blocked_retry_attempts: 1
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 910, chat_id: 46, user_id: nil, username: nil, text: "/project new"))

    assert_equal(1, client.messages.size)
    assert_match("Please provide a project name: /project new <name>.", client.messages.last[:text])
    assert_match("telegram clarify chat=46", out.string)
  end

  def test_handle_routes_project_setup_turns_to_rails_api_before_runtime_flow
    Dir.mktmpdir("redwright-telegram-handler-rails-project-setup-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        fake_flow = Object.new
        fake_flow.define_singleton_method(:process) do |**_kwargs|
          raise "flow should not run for Rails-backed project setup"
        end
        runtime_dispatcher = Redwright::ServerRuntimeDispatcher.new(
          flow: fake_flow,
          blocked_retry_attempts: 1,
          project_store: project_store,
          projects_root: bootstrap.projects_root
        )
        setup_client = FakeProjectSetupClient.new
        project_setup_adapter = Redwright::TelegramProjectSetupAdapter.new(client: setup_client)
        client = FakeTelegramClient.new([])
        out = StringIO.new
        handler = Redwright::TelegramRuntimeHandler.new(
          flow: fake_flow,
          telegram_client: client,
          out: out,
          err: StringIO.new,
          blocked_retry_attempts: 1,
          operational_dispatcher: runtime_dispatcher,
          project_setup_adapter: project_setup_adapter
        )

        handler.handle(Redwright::TelegramEvent.new(update_id: 1, chat_id: 46, user_id: 77, username: "tester", text: "/project new happy-cli"))
        handler.handle(Redwright::TelegramEvent.new(update_id: 2, chat_id: 46, user_id: 77, username: "tester", text: "acme/happy-cli"))

        assert_equal(%w[StartProjectSetup AdvanceProjectSetup], setup_client.calls.map { |call| call[:name] })
        assert_equal(2, client.messages.size)
        assert_match("What should this project do?", client.messages.first[:text])
        assert_match("What type of project", client.messages.last[:text])
        assert_match("telegram rails_project_setup chat=46 command=project_new state=collecting_context", out.string)
        assert_match("telegram rails_project_setup chat=46 command=project_setup_advance state=collecting_context", out.string)
        assert_equal([], project_store.list)
        refute(File.directory?(File.join(bootstrap.projects_root, "happy-cli")))
      end
    end
  end

  def test_handle_routes_quoted_project_new_with_description_to_rails_api_before_runtime_flow
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      raise "flow should not run for Rails-backed quoted project setup"
    end
    setup_client = FakeProjectSetupClient.new
    project_setup_adapter = Redwright::TelegramProjectSetupAdapter.new(client: setup_client)
    client = FakeTelegramClient.new([])
    out = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: StringIO.new,
      blocked_retry_attempts: 1,
      project_setup_adapter: project_setup_adapter
    )

    handler.handle(
      Redwright::IngressEvent.new(
        external_message_id: 4,
        external_chat_id: 46,
        sender_id: 77,
        username: "tester",
        transport: "telegram",
        text: '/project new "notes-cli" "A small command line notes manager with local file storage"'
      )
    )

    assert_equal(["StartProjectSetup"], setup_client.calls.map { |call| call[:name] })
    assert_equal("notes-cli", setup_client.calls.first[:payload].fetch("project_name"))
    assert_equal("A small command line notes manager with local file storage", setup_client.calls.first[:payload].fetch("description"))
    refute_includes(setup_client.calls.first[:payload].keys, "repository_input")
    assert_equal("telegram:chat:46:user:77", setup_client.calls.first[:actor_identifier])
    assert_equal("telegram-46-4-start-project-setup", setup_client.calls.first[:request_id])
    assert_equal(1, client.messages.size)
    assert_match("What type of project", client.messages.last[:text])
    assert_match("telegram rails_project_setup chat=46 command=project_new state=collecting_context", out.string)
  end

  def test_handle_project_setup_adapter_failure_does_not_fall_back_to_runtime
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      raise "flow should not run after Rails project setup adapter failure"
    end
    failing_adapter = Object.new
    failing_adapter.define_singleton_method(:handle) do |*_args, **_kwargs|
      raise "rails api down"
    end
    client = FakeTelegramClient.new([])
    out = StringIO.new
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: StringIO.new,
      blocked_retry_attempts: 1,
      project_setup_adapter: failing_adapter
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 3, chat_id: 46, user_id: 77, username: "tester", text: "/project new happy-cli"))

    assert_equal(1, client.messages.size)
    assert_match("Rails project setup API failed: rails api down", client.messages.last[:text])
    assert_match("telegram rails_project_setup_error chat=46", out.string)
  end

  def test_handle_rewrites_operational_slashes_to_explicit_planner_hints
    fake_flow = Object.new
    captured = []
    fake_flow.define_singleton_method(:process) do |**kwargs|
      captured << kwargs
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-op-hint"),
        alignment: nil,
        action_results: []
      )
    end

    seen = []
    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      seen << text
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: text,
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: FakeTelegramClient.new([]),
      out: StringIO.new,
      err: StringIO.new,
      blocked_retry_attempts: 1,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 804, chat_id: 46, user_id: nil, username: nil, text: "/project list"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 805, chat_id: 46, user_id: nil, username: nil, text: "/project where"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 806, chat_id: 46, user_id: nil, username: nil, text: "/repo clone https://example.com/acme/repo.git"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 807, chat_id: 46, user_id: nil, username: nil, text: "/repo status"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 808, chat_id: 46, user_id: nil, username: nil, text: "/repo undo"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 809, chat_id: 46, user_id: nil, username: nil, text: "/plan start"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 810, chat_id: 46, user_id: nil, username: nil, text: "/plan continue"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 811, chat_id: 46, user_id: nil, username: nil, text: "/plan stop-and-apply"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 812, chat_id: 46, user_id: nil, username: nil, text: "/trace on"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 813, chat_id: 46, user_id: nil, username: nil, text: "/trace off"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 814, chat_id: 46, user_id: nil, username: nil, text: "/trace status"))
    handler.handle(Redwright::TelegramEvent.new(update_id: 815, chat_id: 46, user_id: nil, username: nil, text: "/help"))

    assert(seen.any? { |t| t.include?("List known projects") })
    assert(seen.any? { |t| t.include?("Show the current active project") })
    assert(seen.any? { |t| t.include?("Clone repository https://example.com/acme/repo.git") })
    assert(seen.any? { |t| t.include?("Show repository status") })
    assert(seen.any? { |t| t.include?("Undo the latest safe repository changes") })
    assert(seen.any? { |t| t.include?("Start an explicit planning and slicing workflow") })
    assert(seen.any? { |t| t.include?("Continue with current context") })
    assert(seen.any? { |t| t.include?("Stop asking clarification questions") })
    assert(seen.any? { |t| t.include?("Enable runtime trace output") })
    assert(seen.any? { |t| t.include?("Disable runtime trace output") })
    assert(seen.any? { |t| t.include?("Show current runtime trace status") })
    assert(seen.any? { |t| t.include?("Show help for runtime commands") })
    assert_equal(12, captured.size)
  end

  def test_handle_rewrites_project_new_with_description_to_planner_hint
    fake_flow = Object.new
    captured = []
    fake_flow.define_singleton_method(:process) do |**kwargs|
      captured << kwargs
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-op-hint"),
        alignment: nil,
        action_results: []
      )
    end

    seen = []
    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      seen << text
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: text,
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: FakeTelegramClient.new([]),
      out: StringIO.new,
      err: StringIO.new,
      blocked_retry_attempts: 1,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter
    )

    handler.handle(
      Redwright::TelegramEvent.new(
        update_id: 920,
        chat_id: 46,
        user_id: nil,
        username: nil,
        text: "/project new create a Go app named cubix with ascii art"
      )
    )

    assert_equal(1, captured.size)
    assert(seen.any? { |t| t.include?("Create a new project. User request: create a Go app named cubix with ascii art") })
  end

  def test_handle_dispatches_planner_operational_project_new_intent
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      raise "flow should not run when planner emits operational intent"
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "meta",
        message: text,
        operational_intent: "project_new",
        operational_scope: "runtime",
        operational_args: { "project_name" => "cubix" },
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    captured = []
    fake_operational_dispatcher = Object.new
    fake_operational_dispatcher.define_singleton_method(:call) do |request|
      captured << request
      {
        "status" => "ok",
        "command" => "new",
        "project_id" => "project-cubix",
        "workstream_id" => "none",
        "task_id" => "none",
        "state" => "executing"
      }
    end

    chat_context_upserts = []
    fake_chat_context_store = Object.new
    fake_chat_context_store.define_singleton_method(:upsert) do |**kwargs|
      chat_context_upserts << kwargs
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
      intent_interpreter: fake_interpreter,
      operational_dispatcher: fake_operational_dispatcher,
      chat_context_store: fake_chat_context_store
    )

    handler.handle(
      Redwright::TelegramEvent.new(
        update_id: 921,
        chat_id: 46,
        user_id: nil,
        username: nil,
        text: "Create a new Go app named cubix with ascii art"
      )
    )

    assert_equal(1, captured.size)
    payload = captured.first.fetch("payload")
    assert_equal("project_new", payload["operational_intent"])
    assert_equal("cubix", payload.fetch("operational_args").fetch("project_name"))
    assert_equal(
      [{ chat_id: 46, project_id: "project-cubix", workstream_id: nil }],
      chat_context_upserts
    )
    assert_match("Project created and active.", client.messages.last[:text])
    refute_match("project=project-cubix", client.messages.last[:text])
    refute_match("trace=", client.messages.last[:text])
    assert_match("telegram planner_operational chat=46 command=project_new", out.string)
  end

  def test_handle_project_new_operational_message_includes_backtick_telemetry_in_debug_mode
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      raise "flow should not run when planner emits operational intent"
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "meta",
        message: text,
        operational_intent: "project_new",
        operational_scope: "runtime",
        operational_args: { "project_name" => "cubix" },
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    fake_operational_dispatcher = Object.new
    fake_operational_dispatcher.define_singleton_method(:call) do |_request|
      {
        "status" => "ok",
        "command" => "new",
        "project_id" => "project-cubix",
        "workstream_id" => "ws-7",
        "task_id" => "task-8",
        "state" => "executing"
      }
    end

    client = FakeTelegramClient.new([])
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      blocked_retry_attempts: 1,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter,
      operational_dispatcher: fake_operational_dispatcher,
      show_operational_telemetry: true
    )

    handler.handle(
      Redwright::TelegramEvent.new(
        update_id: 922,
        chat_id: 46,
        user_id: nil,
        username: nil,
        text: "Create a new Go app named cubix with ascii art"
      )
    )

    text = client.messages.last[:text]
    assert_match("Project created and active.", text)
    assert_match("Debug:", text)
    assert_match("project=`project-cubix`", text)
    assert_match("workstream=`ws-7`", text)
    assert_match("task=`task-8`", text)
    assert_match("trace=`trc-", text)
  end

  def test_handle_emits_inferred_skill_activation_telemetry
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-skill"),
        alignment: nil,
        action_results: []
      )
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: text,
        skill_requested: "repo-bootstrap",
        skill_mode: "inferred",
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

    handler.handle(Redwright::TelegramEvent.new(update_id: 93, chat_id: 48, user_id: nil, username: nil, text: "bootstrap repo"))

    assert_match("telegram skill chat=48 name=repo-bootstrap mode=inferred confidence=0.8 reason=planner_skill_inferred", out.string)
    assert_equal("", err.string)
  end

  def test_handle_runs_skill_subloop_and_handoffs_back_to_main_loop
    fake_flow = Object.new
    processed = 0
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      processed += 1
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-subloop"),
        alignment: nil,
        action_results: []
      )
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: text,
        skill_requested: "repo-bootstrap",
        skill_mode: "inferred",
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      ).tap do |decision|
        decision.define_singleton_method(:skill_actions) do
          [{ "id" => "s1", "type" => "analyze", "args" => {} }]
        end
      end
    end

    fake_subloop = Object.new
    fake_subloop.define_singleton_method(:run) do |actions:, cancel_requested:|
      TelegramRuntimeHandlerTest::FakeWorkstream.new(
        id: "subloop",
        state: "ok"
      )
      Redwright::SkillSubloopExecutor::Result.new(
        status: "ok",
        attempts: actions.size,
        terminal_reason: "success",
        executed_actions: actions.size,
        last_error: ""
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
      intent_interpreter: fake_interpreter,
      skill_subloop_executor: fake_subloop
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 94, chat_id: 49, user_id: nil, username: nil, text: "bootstrap repo"))

    assert_equal(1, processed)
    assert_match("telegram skill_subloop chat=49 status=ok reason=success attempts=1 executed_actions=1", out.string)
    assert_equal("", err.string)
  end

  def test_handle_routes_skill_stop_and_apply_slash_to_persisted_control_stop
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      raise "process should not run for /skill stop-and-apply"
    end
    fake_flow.define_singleton_method(:control) do |**_kwargs|
      raise "control should not run for /skill stop-and-apply"
    end

    calls = []
    fake_clarification_store = Object.new
    fake_clarification_store.define_singleton_method(:open_control_stop) do |**kwargs|
      calls << kwargs
      nil
    end

    client = FakeTelegramClient.new([])
    out = StringIO.new
    err = StringIO.new
    fake_resolver = Object.new
    fake_resolver.define_singleton_method(:resolve) do |chat_id:, text:|
      Redwright::TelegramContextResolver::Resolution.new(
        resolved: true,
        project_ref: "project-1",
        project_path: "/tmp/project-1",
        workstream_id: "ws-1",
        question: nil
      )
    end
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: out,
      err: err,
      context_resolver: fake_resolver,
      blocked_retry_attempts: 1,
      clarification_session_store: fake_clarification_store
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 816, chat_id: 46, user_id: nil, username: nil, text: "/skill stop-and-apply"))

    assert_equal(1, calls.size)
    assert_equal(46, calls.first[:chat_id])
    assert_equal("ws-1", calls.first[:workstream_id])
    assert_equal(true, calls.first[:accepted_partial])
    assert_equal("skill_stop_and_apply", calls.first[:terminal_reason])
    assert_match("telegram skill_control chat=46 command=stop-and-apply", out.string)
    assert_equal("", err.string)
  end

  def test_handle_closes_control_stop_session_after_canceled_skill_subloop
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-subloop-cancel"),
        alignment: nil,
        action_results: []
      )
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: text,
        skill_requested: "repo-bootstrap",
        skill_mode: "inferred",
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      ).tap do |decision|
        decision.define_singleton_method(:skill_actions) do
          [{ "id" => "s1", "type" => "analyze", "args" => {} }]
        end
      end
    end

    fake_pending = Struct.new(:id, :gap_type, keyword_init: true).new(id: "cls-stop", gap_type: "control_stop")
    advances = []
    fake_clarification_store = Object.new
    fake_clarification_store.define_singleton_method(:get_open) do |**kwargs|
      fake_pending
    end
    fake_clarification_store.define_singleton_method(:advance) do |**kwargs|
      advances << kwargs
      nil
    end

    fake_subloop = Object.new
    fake_subloop.define_singleton_method(:run) do |actions:, cancel_requested:|
      cancel_requested.call
      Redwright::SkillSubloopExecutor::Result.new(
        status: "error",
        attempts: 0,
        terminal_reason: "canceled",
        executed_actions: 0,
        last_error: ""
      )
    end

    fake_resolver = Object.new
    fake_resolver.define_singleton_method(:resolve) do |chat_id:, text:|
      Redwright::TelegramContextResolver::Resolution.new(
        resolved: true,
        project_ref: "project-1",
        project_path: "/tmp/project-1",
        workstream_id: "ws-1",
        question: nil
      )
    end

    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: FakeTelegramClient.new([]),
      out: StringIO.new,
      err: StringIO.new,
      blocked_retry_attempts: 1,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter,
      skill_subloop_executor: fake_subloop,
      clarification_session_store: fake_clarification_store,
      context_resolver: fake_resolver
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 817, chat_id: 49, user_id: nil, username: nil, text: "bootstrap repo"))

    assert_equal(1, advances.size)
    assert_equal("cls-stop", advances.first[:session_id])
    assert_equal("closed", advances.first[:status])
    assert_equal(true, advances.first.dig(:resolved_fields, "accepted_partial"))
    assert_equal("skill_stop_and_apply", advances.first.dig(:resolved_fields, "skill_subloop_terminal_reason"))
  end

  def test_handle_uses_chat_level_pending_planner_gap_when_workstream_specific_lookup_misses
    fake_flow = Object.new
    captured = {}
    fake_flow.define_singleton_method(:process) do |**kwargs|
      captured.merge!(kwargs)
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-gap"),
        alignment: nil,
        action_results: []
      )
    end

    fake_pending = Struct.new(:id, :gap_type, :payload, :last_question_id, keyword_init: true).new(
      id: "cls-1",
      gap_type: "planner_gap",
      payload: {
        "base_message" => "Create project",
        "gap" => { "field" => "test_framework" }
      },
      last_question_id: "q1"
    )
    fake_clarification_store = Object.new
    calls = []
    advances = []
    fake_clarification_store.define_singleton_method(:get_open) do |**kwargs|
      calls << kwargs
      kwargs[:workstream_id] ? nil : fake_pending
    end
    fake_clarification_store.define_singleton_method(:advance) do |**kwargs|
      advances << kwargs
      nil
    end
    fake_clarification_store.define_singleton_method(:cancel_open) do |**_kwargs|
      nil
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: text,
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end
    fake_context_resolver = Object.new
    fake_context_resolver.define_singleton_method(:resolve) do |chat_id:, text:|
      Redwright::TelegramContextResolver::Resolution.new(
        resolved: true,
        project_ref: "project-1",
        project_path: "/tmp/project-1",
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
      blocked_retry_attempts: 1,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter,
      clarification_session_store: fake_clarification_store,
      context_resolver: fake_context_resolver
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 95, chat_id: 50, user_id: nil, username: nil, text: "RSpec"))

    assert_equal(2, calls.size)
    assert_equal(1, advances.size)
    assert_includes(captured[:message], "Create project")
    assert_includes(captured[:message], "Clarification for test_framework: RSpec")
    assert_equal("", err.string)
  end

  def test_handle_closes_pending_gap_on_continue_with_current_context_semantic
    fake_flow = Object.new
    captured = {}
    fake_flow.define_singleton_method(:process) do |**kwargs|
      captured.merge!(kwargs)
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-continue-gap"),
        alignment: nil,
        action_results: []
      )
    end

    fake_pending = Struct.new(:id, :gap_type, :payload, :last_question_id, keyword_init: true).new(
      id: "cls-2",
      gap_type: "planner_gap",
      payload: {
        "base_message" => "Implement the feature using current assumptions",
        "gap" => { "field" => "project_name" }
      },
      last_question_id: "q2"
    )
    fake_clarification_store = Object.new
    advances = []
    fake_clarification_store.define_singleton_method(:get_open) do |**_kwargs|
      fake_pending
    end
    fake_clarification_store.define_singleton_method(:advance) do |**kwargs|
      advances << kwargs
      nil
    end
    fake_clarification_store.define_singleton_method(:cancel_open) do |**_kwargs|
      nil
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: text,
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
      intent_interpreter: fake_interpreter,
      clarification_session_store: fake_clarification_store
    )

    handler.handle(
      Redwright::TelegramEvent.new(
        update_id: 96,
        chat_id: 51,
        user_id: nil,
        username: nil,
        text: "continua con lo que tengas"
      )
    )

    assert_equal("Implement the feature using current assumptions", captured[:message])
    assert_equal(1, advances.size)
    assert_equal(true, advances.first.dig(:resolved_fields, "continue_with_current_context"))
    assert_equal("", err.string)
  end

  def test_handle_keeps_slash_precedence_over_hints
    fake_flow = Object.new
    captured = {}
    fake_flow.define_singleton_method(:process) do |**kwargs|
      captured.merge!(kwargs)
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-priority"),
        alignment: nil,
        action_results: []
      )
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      raise "slash should take precedence over hints" unless text.start_with?("Switch active project to")
      raise "hints should not override slash command" if text.include?("Hint context:")

      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: text,
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

    handler.handle(
      Redwright::TelegramEvent.new(
        update_id: 92,
        chat_id: 47,
        user_id: nil,
        username: nil,
        text: "/project switch rw @mode: direct @tests: required"
      )
    )

    assert_includes(captured[:message], "Switch active project")
    assert_equal("", err.string)
  end

  def test_handle_treats_yes_without_active_gap_as_clarify_not_meta
    fake_flow = Object.new
    processed = 0
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      processed += 1
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-yes"),
        alignment: nil,
        action_results: []
      )
    end

    fake_clarification_store = Object.new
    fake_clarification_store.define_singleton_method(:get_open) do |**_kwargs|
      nil
    end
    fake_clarification_store.define_singleton_method(:advance) do |**_kwargs|
      nil
    end
    fake_clarification_store.define_singleton_method(:cancel_open) do |**_kwargs|
      nil
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "meta",
        message: "unexpected planner path",
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
      intent_interpreter: fake_interpreter,
      clarification_session_store: fake_clarification_store
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 201, chat_id: 61, user_id: nil, username: nil, text: "yes"))

    assert_equal(0, processed)
    assert_match("No active question to confirm", client.messages.last[:text])
    assert_equal("", err.string)
  end

  def test_handle_retries_change_turn_after_recoverable_macro_shape_error
    fake_flow = Object.new
    process_calls = 0
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      process_calls += 1
      if process_calls == 1
        raise RuntimeError, "action_failed id=a1 type=write_files: write_files_missing_files"
      end

      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-retry-ok"),
        alignment: nil,
        action_results: []
      )
    end

    interpreter_calls = 0
    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:|
      interpreter_calls += 1
      TelegramRuntimeHandlerTest::FakeDecision.new(
        intent: "change",
        message: text,
        actions: [],
        gaps: [],
        control_intent: "none",
        control_scope: "none",
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
      blocked_retry_attempts: 2,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 202, chat_id: 62, user_id: nil, username: nil, text: "create project scaffold"))

    assert_equal(2, process_calls)
    assert_equal(2, interpreter_calls)
    assert_match("Started task task-retry-ok in project project-1.", client.messages.last[:text])
    assert_equal("", err.string)
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
    assert_match("Actions: 1 succeeded, 1 failed.", client.messages.last[:text])
    assert_match("telegram processed chat=9 task=task-x", out.string)
    assert_equal("", err.string)
  end

  def test_handle_renders_zero_action_counters_as_integers
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      FakeResult.new(
        project: FakeProject.new(id: "project-zero"),
        workstream: FakeWorkstream.new(id: "ws-zero", state: "executing"),
        task: FakeTask.new(id: "task-zero"),
        alignment: nil,
        action_results: []
      )
    end

    client = FakeTelegramClient.new([])
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      blocked_retry_attempts: 1
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 911, chat_id: 9, user_id: nil, username: nil, text: "do stuff"))

    assert_match("Actions: 0 succeeded, 0 failed.", client.messages.last[:text])
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

  def test_handle_json_envelope_keeps_execution_summary_contract
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      FakeResult.new(
        project: FakeProject.new(id: "project-json"),
        workstream: FakeWorkstream.new(id: "ws-json", state: "executing"),
        task: FakeTask.new(id: "task-json"),
        alignment: nil,
        action_results: [
          FakeActionResult.new(action_id: "a1", status: "ok")
        ]
      )
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |**_kwargs|
      FakeDecision.new(
        intent: "change",
        message: "do stuff",
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
        raw_output: "{}"
      )
    end

    client = FakeTelegramClient.new([])
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      blocked_retry_attempts: 1,
      send_json_envelope: true,
      intent_interpreter: fake_interpreter
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 12, chat_id: 11, user_id: nil, username: nil, text: "do stuff"))

    json_text = client.messages.last[:text].sub(/\A```json\n/, "").sub(/\n```\z/, "")
    payload = JSON.parse(json_text)
    assert_equal("ok", payload["status"])
    execution = payload.fetch("runtime").fetch("execution")
    assert_equal(1, execution["total_actions"])
    assert_equal(1, execution["succeeded_actions"])
    assert_equal(0, execution["failed_actions"])
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

  def test_handle_injects_normalized_failures_into_refinement_and_persists_feedback_fingerprints
    flow_calls = 0
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      flow_calls += 1
      FakeResult.new(
        project: FakeProject.new(id: "project-r"),
        workstream: FakeWorkstream.new(id: "ws-r", state: "executing"),
        task: FakeTask.new(id: "task-r"),
        alignment: nil,
        action_results: [
          FakeActionResult.new(action_id: "a1", action_type: "run_test", status: "error", error_message: "tests failed")
        ]
      )
    end

    interp_calls = []
    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:, **_kwargs|
      interp_calls << text
      FakeDecision.new(
        intent: "change",
        message: "apply change",
        actions: [],
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    quality_runs = 0
    fake_quality_runner = Object.new
    fake_quality_runner.define_singleton_method(:run) do |**_kwargs|
      quality_runs += 1
      quality_runs == 1 ? [FakeQualityCheck.new(name: "test", status: "error")] : [FakeQualityCheck.new(name: "test", status: "ok")]
    end

    fake_resolver = Object.new
    fake_resolver.define_singleton_method(:resolve) do |**_kwargs|
      Redwright::TelegramContextResolver::Resolution.new(
        resolved: true,
        project_ref: "p1",
        project_path: "/tmp/project",
        workstream_id: nil,
        question: nil
      )
    end

    fake_prompt_loader = Object.new
    fake_prompt_loader.define_singleton_method(:build) do |**_kwargs|
      { quality: { auto_validate: true, lint_command: nil, test_command: "bundle exec rake test" } }
    end

    feedback_events = []
    fake_feedback_store = Object.new
    fake_feedback_store.define_singleton_method(:create) do |**kwargs|
      feedback_events << kwargs
      "efd-1"
    end

    client = FakeTelegramClient.new([])
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      context_resolver: fake_resolver,
      blocked_retry_attempts: 2,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter,
      prompt_context_loader: fake_prompt_loader,
      quality_gate_runner: fake_quality_runner,
      execution_feedback_store: fake_feedback_store
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 97, chat_id: 52, user_id: nil, username: nil, text: "do work"))

    assert_equal(2, flow_calls)
    assert_equal(2, interp_calls.size)
    assert_includes(interp_calls.last, "normalized_failures:")
    assert_includes(interp_calls.last, "last_execution_results:")
    assert(!feedback_events.empty?)
    assert_equal("task-r", feedback_events.first[:task_id])
  end

  def test_normalized_change_loop_attempts_enforces_runtime_upper_bound
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: Object.new,
      telegram_client: FakeTelegramClient.new([]),
      out: StringIO.new,
      err: StringIO.new,
      blocked_retry_attempts: 1
    )

    assert_equal(1, handler.send(:normalized_change_loop_attempts, 0))
    assert_equal(3, handler.send(:normalized_change_loop_attempts, 3))
    assert_equal(8, handler.send(:normalized_change_loop_attempts, 99))
  end

  def test_handle_stops_with_timeout_when_quality_fails_and_deadline_reached
    flow_calls = 0
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      flow_calls += 1
      FakeResult.new(
        project: FakeProject.new(id: "project-t"),
        workstream: FakeWorkstream.new(id: "ws-t", state: "executing"),
        task: FakeTask.new(id: "task-t"),
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
    fake_quality_runner.define_singleton_method(:run) do |**_kwargs|
      [FakeQualityCheck.new(name: "test", status: "error")]
    end

    fake_resolver = Object.new
    fake_resolver.define_singleton_method(:resolve) do |**_kwargs|
      Redwright::TelegramContextResolver::Resolution.new(
        resolved: true,
        project_ref: "p1",
        project_path: "/tmp/project",
        workstream_id: nil,
        question: nil
      )
    end

    fake_prompt_loader = Object.new
    fake_prompt_loader.define_singleton_method(:build) do |**_kwargs|
      { quality: { auto_validate: true, lint_command: nil, test_command: "bundle exec rake test" } }
    end

    client = FakeTelegramClient.new([])
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      context_resolver: fake_resolver,
      blocked_retry_attempts: 5,
      max_change_turn_seconds: 0,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter,
      prompt_context_loader: fake_prompt_loader,
      quality_gate_runner: fake_quality_runner
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 24, chat_id: 9, user_id: nil, username: nil, text: "do work"))

    assert_equal(1, flow_calls)
    assert_match("Attempts: 1 (terminal: timeout).", client.messages.last[:text])
  end

  def test_handle_stops_with_clarify_when_refinement_returns_unresolved_gap
    flow_calls = 0
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      flow_calls += 1
      FakeResult.new(
        project: FakeProject.new(id: "project-c2"),
        workstream: FakeWorkstream.new(id: "ws-c2", state: "executing"),
        task: FakeTask.new(id: "task-c2"),
        alignment: nil,
        action_results: [FakeActionResult.new(action_id: "a1", status: "ok")]
      )
    end

    call = 0
    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |text:, model:, **_kwargs|
      call += 1
      if call == 1
        FakeDecision.new(
          intent: "change",
          message: "apply change",
          actions: [],
          gaps: [],
          source: "llm",
          finish_reason: "stop",
          raw_output: "{}"
        )
      else
        FakeDecision.new(
          intent: "change",
          message: "refined change",
          actions: [],
          gaps: [
            { "id" => "g1", "question" => "What is the module name?", "field" => "module_name", "inferred_value" => "", "resolved" => false, "priority" => 1 }
          ],
          source: "llm",
          finish_reason: "stop",
          raw_output: "{}"
        )
      end
    end

    fake_quality_runner = Object.new
    fake_quality_runner.define_singleton_method(:run) do |**_kwargs|
      [FakeQualityCheck.new(name: "test", status: "error")]
    end

    fake_resolver = Object.new
    fake_resolver.define_singleton_method(:resolve) do |**_kwargs|
      Redwright::TelegramContextResolver::Resolution.new(
        resolved: true,
        project_ref: "p1",
        project_path: "/tmp/project",
        workstream_id: nil,
        question: nil
      )
    end

    fake_prompt_loader = Object.new
    fake_prompt_loader.define_singleton_method(:build) do |**_kwargs|
      { quality: { auto_validate: true, lint_command: nil, test_command: "bundle exec rake test" } }
    end

    client = FakeTelegramClient.new([])
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      context_resolver: fake_resolver,
      blocked_retry_attempts: 2,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter,
      prompt_context_loader: fake_prompt_loader,
      quality_gate_runner: fake_quality_runner
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 25, chat_id: 9, user_id: nil, username: nil, text: "mode:structured do work"))

    assert_equal(1, flow_calls)
    assert_match("Attempts: 1 (terminal: clarify).", client.messages.last[:text])
  end

  def test_handle_does_not_crash_when_recoverable_runtime_error_refinement_exits_with_clarify
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      raise "write_files_missing_files"
    end

    call = 0
    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |**_kwargs|
      call += 1
      if call == 1
        FakeDecision.new(
          intent: "change",
          message: "apply change",
          actions: [],
          gaps: [],
          source: "llm",
          finish_reason: "stop",
          raw_output: "{}"
        )
      else
        FakeDecision.new(
          intent: "change",
          message: "need clarification",
          actions: [],
          gaps: [
            { "id" => "g1", "question" => "Which target file should be created?", "field" => "target_file", "resolved" => false, "priority" => 1 }
          ],
          source: "llm",
          finish_reason: "stop",
          raw_output: "{}"
        )
      end
    end

    fake_resolver = Object.new
    fake_resolver.define_singleton_method(:resolve) do |**_kwargs|
      Redwright::TelegramContextResolver::Resolution.new(
        resolved: true,
        project_ref: "p1",
        project_path: "/tmp/project",
        workstream_id: nil,
        question: nil
      )
    end

    fake_prompt_loader = Object.new
    fake_prompt_loader.define_singleton_method(:build) do |**_kwargs|
      { quality: { auto_validate: true, lint_command: nil, test_command: "bundle exec rake test" } }
    end

    client = FakeTelegramClient.new([])
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      context_resolver: fake_resolver,
      blocked_retry_attempts: 2,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter,
      prompt_context_loader: fake_prompt_loader
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 26, chat_id: 9, user_id: nil, username: nil, text: "do work"))

    assert_match("Which target file should be created?", client.messages.last[:text])
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

  def test_change_mode_explicit_override_forces_direct
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      FakeResult.new(
        project: FakeProject.new(id: "project-m1"),
        workstream: FakeWorkstream.new(id: "ws-m1", state: "executing"),
        task: FakeTask.new(id: "task-m1"),
        alignment: nil,
        action_results: []
      )
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |**_kwargs|
      FakeDecision.new(intent: "change", message: "fix bug", actions: [], gaps: [], source: "llm", finish_reason: "stop", raw_output: "{}")
    end

    client = FakeTelegramClient.new([])
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      blocked_retry_attempts: 2,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 30, chat_id: 9, user_id: nil, username: nil, text: "mode:direct fix this parser"))
    assert_match("Mode: direct.", client.messages.last[:text])
    assert_match("Attempts: 1 (terminal: direct_pass).", client.messages.last[:text])
  end

  def test_change_mode_infers_structured_for_planning_language
    flow_calls = 0
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      flow_calls += 1
      FakeResult.new(
        project: FakeProject.new(id: "project-m2"),
        workstream: FakeWorkstream.new(id: "ws-m2", state: "executing"),
        task: FakeTask.new(id: "task-m2"),
        alignment: nil,
        action_results: []
      )
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |**_kwargs|
      FakeDecision.new(intent: "change", message: "create plan and slices", actions: [], gaps: [], source: "llm", finish_reason: "stop", raw_output: "{}")
    end

    client = FakeTelegramClient.new([])
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      blocked_retry_attempts: 2,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 31, chat_id: 9, user_id: nil, username: nil, text: "prepare plan and slice set"))
    assert_equal(1, flow_calls)
    assert_match("Mode: structured.", client.messages.last[:text])
  end

  def test_change_mode_default_is_structured
    flow_calls = 0
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      flow_calls += 1
      FakeResult.new(
        project: FakeProject.new(id: "project-m3"),
        workstream: FakeWorkstream.new(id: "ws-m3", state: "executing"),
        task: FakeTask.new(id: "task-m3"),
        alignment: nil,
        action_results: []
      )
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |**_kwargs|
      FakeDecision.new(intent: "change", message: "small fix", actions: [], gaps: [], source: "llm", finish_reason: "stop", raw_output: "{}")
    end

    client = FakeTelegramClient.new([])
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      blocked_retry_attempts: 2,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 32, chat_id: 9, user_id: nil, username: nil, text: "quick fix"))
    assert_equal(1, flow_calls)
    assert_match("Mode: structured.", client.messages.last[:text])
  end

  def test_handle_stops_with_repeated_fingerprint_terminal_reason
    flow_calls = 0
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      flow_calls += 1
      FakeResult.new(
        project: FakeProject.new(id: "project-rf"),
        workstream: FakeWorkstream.new(id: "ws-rf", state: "executing"),
        task: FakeTask.new(id: "task-rf"),
        alignment: nil,
        action_results: [FakeActionResult.new(action_id: "a1", action_type: "run_test", status: "error", error_message: "tests failed")]
      )
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |**_kwargs|
      FakeDecision.new(
        intent: "change",
        message: "apply change",
        actions: [],
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    fake_quality_runner = Object.new
    fake_quality_runner.define_singleton_method(:run) do |**_kwargs|
      [FakeQualityCheck.new(name: "test", status: "error")]
    end

    fake_resolver = Object.new
    fake_resolver.define_singleton_method(:resolve) do |**_kwargs|
      Redwright::TelegramContextResolver::Resolution.new(
        resolved: true,
        project_ref: "p1",
        project_path: "/tmp/project",
        workstream_id: nil,
        question: nil
      )
    end

    fake_prompt_loader = Object.new
    fake_prompt_loader.define_singleton_method(:build) do |**_kwargs|
      { quality: { auto_validate: true, lint_command: nil, test_command: "bundle exec rake test" } }
    end

    client = FakeTelegramClient.new([])
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      context_resolver: fake_resolver,
      blocked_retry_attempts: 5,
      max_repeated_fingerprint_attempts: 1,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter,
      prompt_context_loader: fake_prompt_loader,
      quality_gate_runner: fake_quality_runner
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 33, chat_id: 53, user_id: nil, username: nil, text: "do work"))

    assert_equal(2, flow_calls)
    assert_match("Attempts: 2 (terminal: repeated_fingerprint).", client.messages.last[:text])
  end

  def test_handle_stops_with_no_progress_terminal_reason
    flow_calls = 0
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      flow_calls += 1
      FakeResult.new(
        project: FakeProject.new(id: "project-np"),
        workstream: FakeWorkstream.new(id: "ws-np", state: "executing"),
        task: FakeTask.new(id: "task-np"),
        alignment: nil,
        action_results: []
      )
    end

    fake_interpreter = Object.new
    fake_interpreter.define_singleton_method(:interpret) do |**_kwargs|
      FakeDecision.new(
        intent: "change",
        message: "apply change",
        actions: [],
        source: "llm",
        finish_reason: "stop",
        raw_output: "{}"
      )
    end

    fake_quality_runner = Object.new
    fake_quality_runner.define_singleton_method(:run) do |**_kwargs|
      [FakeQualityCheck.new(name: "test", status: "error")]
    end

    fake_feedback_normalizer = Object.new
    fake_feedback_normalizer.define_singleton_method(:normalize) do |**_kwargs|
      Redwright::FeedbackNormalizer::Feedback.new(
        normalized_failures: [],
        execution_results: [],
        fingerprints: []
      )
    end

    fake_resolver = Object.new
    fake_resolver.define_singleton_method(:resolve) do |**_kwargs|
      Redwright::TelegramContextResolver::Resolution.new(
        resolved: true,
        project_ref: "p1",
        project_path: "/tmp/project",
        workstream_id: nil,
        question: nil
      )
    end

    fake_prompt_loader = Object.new
    fake_prompt_loader.define_singleton_method(:build) do |**_kwargs|
      { quality: { auto_validate: true, lint_command: nil, test_command: "bundle exec rake test" } }
    end

    client = FakeTelegramClient.new([])
    handler = Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      context_resolver: fake_resolver,
      blocked_retry_attempts: 5,
      max_no_progress_attempts: 2,
      model_name: "gpt-5-mini",
      intent_interpreter: fake_interpreter,
      prompt_context_loader: fake_prompt_loader,
      quality_gate_runner: fake_quality_runner,
      feedback_normalizer: fake_feedback_normalizer
    )

    handler.handle(Redwright::TelegramEvent.new(update_id: 34, chat_id: 54, user_id: nil, username: nil, text: "do work"))

    assert_equal(2, flow_calls)
    assert_match("Attempts: 2 (terminal: no_progress).", client.messages.last[:text])
  end

  def test_parse_slash_command_maps_operational_ticket_and_loop_variants
    handler = build_private_method_handler

    parsed_ticket_pick = handler.send(:parse_slash_command, "/ticket pick")
    parsed_ticket_start = handler.send(:parse_slash_command, "/ticket start task-9")
    parsed_loop_start = handler.send(:parse_slash_command, "/loop start")
    parsed_loop_stop = handler.send(:parse_slash_command, "/loop stop")
    parsed_unknown = handler.send(:parse_slash_command, "/loop maybe")

    assert_equal("operational", parsed_ticket_pick[:kind])
    assert_equal("ticket_pick", parsed_ticket_pick[:command])
    assert_equal("operational", parsed_ticket_start[:kind])
    assert_equal("ticket_start", parsed_ticket_start[:command])
    assert_match("task-9", parsed_ticket_start[:planner_text_fallback])
    assert_equal("operational", parsed_loop_start[:kind])
    assert_equal("loop_start", parsed_loop_start[:command])
    assert_equal("operational", parsed_loop_stop[:kind])
    assert_equal("loop_stop", parsed_loop_stop[:command])
    assert_nil(parsed_unknown)
  end

  def test_build_operational_reply_text_formats_ticket_list_concisely
    handler = build_private_method_handler(show_operational_telemetry: false)
    operational = {
      "command" => "ticket_list",
      "tickets" => [
        { "id" => "task-1", "status" => "in_progress", "description" => "first ticket title" },
        { "id" => "task-2", "status" => "review", "description" => "second ticket title" }
      ]
    }

    reply = handler.send(
      :build_operational_reply_text,
      operational: operational,
      runtime_project_id: "project-1",
      runtime_workstream_id: "none",
      runtime_task_id: "none",
      runtime_state: "executing"
    )

    assert_match("Tickets for", reply)
    assert_match("task-1", reply)
    assert_match("in_progress", reply)
    assert_match("first ticket title", reply)
    assert_match("Trace: none", reply)
  end

  def test_build_operational_reply_text_appends_telemetry_when_enabled
    handler = build_private_method_handler(show_operational_telemetry: true)
    operational = {
      "command" => "project_switch",
      "terminal_reason" => "executing"
    }

    reply = handler.send(
      :build_operational_reply_text,
      operational: operational,
      runtime_project_id: "project-2",
      runtime_workstream_id: "ws-2",
      runtime_task_id: "task-2",
      runtime_state: "executing"
    )

    assert_match("Operational command applied.", reply)
    assert_match("project=project-2", reply)
    assert_match("task=task-2", reply)
    assert_match("Trace: none", reply)
  end

  def test_confirmation_and_continue_semantic_guards
    policy = Object.new
    policy.define_singleton_method(:confirmation_reply_only?) do |text|
      text.to_s.strip.downcase == "yes"
    end
    policy.define_singleton_method(:continue_with_current_context_semantic?) do |text|
      text.to_s.strip.downcase == "continue with current context"
    end
    handler = build_private_method_handler(clarification_policy: policy)

    assert_equal(true, handler.send(:confirmation_reply_only?, "yes"))
    assert_equal(false, handler.send(:confirmation_reply_only?, "dale"))
    assert_equal(false, handler.send(:confirmation_reply_only?, "yes and keep going"))

    assert_equal(true, handler.send(:continue_with_current_context_semantic?, "continue with current context"))
    assert_equal(false, handler.send(:continue_with_current_context_semantic?, "sin mas preguntas, continua"))
    assert_equal(false, handler.send(:continue_with_current_context_semantic?, "no continue"))
  end

  def test_select_change_mode_and_extract_mode_override
    handler = build_private_method_handler
    default_decision = FakeDecision.new(skill_mode: nil)
    direct_decision = FakeDecision.new(skill_mode: "direct")

    assert_equal("direct", handler.send(:extract_mode_override, "mode:direct do work"))
    assert_equal("structured", handler.send(:extract_mode_override, "MODE:STRUCTURED now"))
    assert_nil(handler.send(:extract_mode_override, "no mode override"))

    assert_equal({ mode: "direct", source: "override" }, handler.send(:select_change_mode, event_text: "mode:direct now", decision: default_decision))
    assert_equal({ mode: "structured", source: "default" }, handler.send(:select_change_mode, event_text: "do work", decision: direct_decision))
    assert_equal({ mode: "structured", source: "default" }, handler.send(:select_change_mode, event_text: "do work", decision: default_decision))
  end

  private

  def build_private_method_handler(show_operational_telemetry: false, clarification_policy: nil)
    fake_flow = Object.new
    fake_flow.define_singleton_method(:process) do |**_kwargs|
      TelegramRuntimeHandlerTest::FakeResult.new(
        project: TelegramRuntimeHandlerTest::FakeProject.new(id: "project-1"),
        workstream: TelegramRuntimeHandlerTest::FakeWorkstream.new(id: "ws-1", state: "executing"),
        task: TelegramRuntimeHandlerTest::FakeTask.new(id: "task-1"),
        alignment: nil,
        action_results: []
      )
    end

    Redwright::TelegramRuntimeHandler.new(
      flow: fake_flow,
      telegram_client: FakeTelegramClient.new([]),
      out: StringIO.new,
      err: StringIO.new,
      blocked_retry_attempts: 1,
      show_operational_telemetry: show_operational_telemetry,
      clarification_policy: clarification_policy
    )
  end

end
