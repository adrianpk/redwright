# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "stringio"
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
require "redwright/console/ingress_adapter"
require "redwright/tui/shell"
require "redwright/tui/ingress_adapter"

class CrossChannelParityMatrixTest < Minitest::Test
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

  class ParityInterpreter
    def initialize(unsafe:)
      @unsafe = unsafe
    end

    def interpret(text:, model:, **_kwargs)
      _ = model
      path = @unsafe ? "../escape.txt" : "runtime/parity.txt"
      FakeDecision.new(
        intent: "change",
        message: text.to_s.strip,
        actions: [
          {
            "id" => "write_parity",
            "type" => "write_file",
            "args" => { "path" => path, "content" => "ok\n" },
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

  def test_cross_channel_parity_for_successful_mutation
    telegram = run_scenario(channel: :telegram, unsafe: false)
    console = run_scenario(channel: :console, unsafe: false)
    tui = run_scenario(channel: :tui, unsafe: false)

    [telegram, console, tui].each do |result|
      assert_equal("success", result[:terminal_reason])
      assert_equal(["ok"], result[:action_statuses])
      assert_equal(["write_file"], result[:action_types])
      assert_equal(true, result[:inside_file_exists])
      assert_equal(false, result[:outside_file_exists])
    end
  end

  def test_cross_channel_parity_for_out_of_root_mutation_block
    telegram = run_scenario(channel: :telegram, unsafe: true)
    console = run_scenario(channel: :console, unsafe: true)
    tui = run_scenario(channel: :tui, unsafe: true)

    assert_equal(telegram[:terminal_reason], console[:terminal_reason])
    assert_equal(console[:terminal_reason], tui[:terminal_reason])
    [telegram, console, tui].each do |result|
      assert_equal(["error"], result[:action_statuses])
      assert_equal(["write_file"], result[:action_types])
      assert_equal(false, result[:inside_file_exists])
      assert_equal(false, result[:outside_file_exists])
      assert_includes(result[:action_errors].first.to_s, "path_outside_project")
    end
  end

  private

  def run_scenario(channel:, unsafe:)
    Dir.mktmpdir("redwright-cross-channel-parity-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        workstream_store = Redwright::WorkstreamStore.new(bootstrap.db_path)
        task_store = Redwright::TaskStore.new(bootstrap.db_path)
        action_store = Redwright::ActionExecutionStore.new(bootstrap.db_path)
        chat_context_store = Redwright::ChatContextStore.new(bootstrap.db_path)
        clarification_session_store = Redwright::ClarificationSessionStore.new(bootstrap.db_path)

        project_path = File.join(bootstrap.projects_root, "alpha")
        FileUtils.mkdir_p(project_path)
        project_store.register(path: project_path, aliases: ["alpha"])

        flow = Redwright::RuntimeFlow.new(
          project_store: project_store,
          workstream_store: workstream_store,
          task_store: task_store,
          alignment_store: Redwright::AlignmentStore.new(bootstrap.db_path),
          alignment_interruption_store: Redwright::AlignmentInterruptionStore.new(bootstrap.db_path),
          primitive_executor: Redwright::PrimitiveExecutor.new(
            allowed_projects_root: bootstrap.projects_root,
            enforce_mutating_projects_root: true
          ),
          action_execution_store: action_store
        )

        resolver = Redwright::TelegramContextResolver.new(
          project_store: project_store,
          chat_context_store: chat_context_store,
          projects_root: bootstrap.projects_root,
          clarification_session_store: clarification_session_store
        )

        adapter, output_text = build_channel_adapter(channel: channel, text: "alpha do work")
        handler = Redwright::TelegramRuntimeHandler.new(
          flow: flow,
          telegram_client: adapter,
          out: StringIO.new,
          err: StringIO.new,
          context_resolver: resolver,
          chat_context_store: chat_context_store,
          clarification_session_store: clarification_session_store,
          blocked_retry_attempts: 1,
          intent_interpreter: ParityInterpreter.new(unsafe: unsafe)
        )

        cursor = nil
        runner = Redwright::DaemonRunner.new(
          ingress_poller: lambda {
            poll = adapter.poll(cursor: cursor, timeout_seconds: 0)
            cursor = poll.next_cursor
            poll.events
          },
          event_handler: ->(event) { handler.handle(event) }
        )
        runner.run(loop_interval_seconds: 0.0, max_iterations: 1)
        adapter.close if adapter.respond_to?(:close)

        latest_task = task_store.list.first
        action_rows = action_store.list(task_id: latest_task.id)
        terminal_text = case channel
                        when :telegram
                          adapter.sent_messages.last[:text]
                        else
                          output_text.string
                        end

        inside_file = File.join(project_path, "runtime", "parity.txt")
        outside_file = File.expand_path("../escape.txt", project_path)

        {
          terminal_reason: extract_terminal_reason(terminal_text),
          action_statuses: action_rows.map(&:status),
          action_types: action_rows.map(&:action_type),
          action_errors: action_rows.map(&:error_message),
          inside_file_exists: File.file?(inside_file),
          outside_file_exists: File.file?(outside_file)
        }
      end
    end
  end

  def build_channel_adapter(channel:, text:)
    case channel
    when :telegram
      adapter = Redwright::SimulatedIngressAdapter.new(
        events: [Redwright::SimulatedIngressAdapter.event(external_message_id: 1, external_chat_id: 700, text: text)]
      )
      [adapter, nil]
    when :console
      out = StringIO.new
      adapter = Redwright::Console::IngressAdapter.new(input: StringIO.new("#{text}\n"), output: out, local_chat_id: 700)
      [adapter, out]
    when :tui
      out = StringIO.new
      shell = Redwright::Tui::Shell.new(output: out)
      adapter = Redwright::Tui::IngressAdapter.new(input: StringIO.new("#{text}\n"), shell: shell, local_chat_id: 700)
      [adapter, out]
    else
      raise ArgumentError, "unsupported channel"
    end
  end

  def extract_terminal_reason(text)
    match = text.to_s.match(/terminal:\s*([a-z_]+)/i)
    return "unknown" unless match

    match[1]
  end
end
