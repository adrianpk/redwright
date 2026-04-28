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
require "redwright/alignment_store"
require "redwright/alignment_interruption_store"
require "redwright/runtime_flow"
require "redwright/primitive_executor"
require "redwright/telegram_runtime_handler"
require "redwright/chat_context_store"
require "redwright/telegram_context_resolver"
require "redwright/daemon_runner"
require "redwright/simulated_ingress_adapter"

class SimulatedIngressE2ETest < Minitest::Test
  FakeDecision = Struct.new(:intent, :message, :actions, :source, :finish_reason, :raw_output, keyword_init: true)

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

  def test_simulated_ingress_handles_multi_turn_multi_project_pause_resume_and_fs_effects
    Dir.mktmpdir("redwright-simulated-e2e-") do |dir|
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
        assert_operator(tasks.size, :>=, 5)
        assert(tasks.any? { |t| t.description.include?("pause workstream") })
        assert(tasks.any? { |t| t.description.include?("resume workstream") })

        alpha_ws = workstream_store.find_latest_for_project(project_id: alpha.id)
        beta_ws = workstream_store.find_latest_for_project(project_id: beta.id)
        assert_equal("executing", alpha_ws.state)
        assert_equal("executing", beta_ws.state)
      end
    end
  end
end
