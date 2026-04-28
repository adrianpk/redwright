# frozen_string_literal: true

require "tmpdir"
require "socket"
require "json"
require "timeout"
require "thread"
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
require "redwright/skill_dispatcher"
require "redwright/local_ipc_server"
require "redwright/local_ipc_session_registry"
require "redwright/server_runtime_dispatcher"

class ServerClientRecoveryParityTest < Minitest::Test
  def test_two_clients_reconnect_and_mutate_same_project_with_single_server
    Dir.mktmpdir("redwright-server-recovery-parity-") do |dir|
      Dir.chdir(dir) do
        bootstrap = Redwright::Bootstrap.new(mode: :dev).call
        project_path = File.join(bootstrap.projects_root, "alpha")
        FileUtils.mkdir_p(project_path)
        project_store = Redwright::ProjectStore.new(bootstrap.db_path)
        project_store.register(path: project_path, aliases: ["alpha"])

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
          action_execution_store: Redwright::ActionExecutionStore.new(bootstrap.db_path),
          skill_dispatcher: Redwright::SkillDispatcher.new
        )
        dispatcher = Redwright::ServerRuntimeDispatcher.new(flow: flow, blocked_retry_attempts: 1)
        socket_path = File.join(bootstrap.state_dir, "rw.sock")
        server = Redwright::LocalIpcServer.new(
          socket_path: socket_path,
          session_registry: Redwright::LocalIpcSessionRegistry.new,
          dispatcher: ->(request) { dispatcher.call(request) }
        )

        server_thread = Thread.new do
          4.times { server.run_once }
        ensure
          server.close
        end
        Timeout.timeout(2) { sleep(0.01) until File.exist?(socket_path) }

        send_line(socket_path, "{\"type\":\"subscribe\",\"session_id\":\"c1\",\"payload\":{\"channel\":\"tui\"}}\n")
        send1 = send_line(
          socket_path,
          JSON.generate(
            {
              type: "send",
              session_id: "c1",
              payload: {
                channel: "tui",
                project_ref: "alpha",
                intent: "change",
                message: "write from c1",
                actions: [
                  {
                    id: "w1",
                    type: "write_file",
                    args: { path: "runtime/c1.txt", content: "one\n" },
                    requires_confirmation: false,
                    timeout_ms: 10_000,
                    on_failure: "abort"
                  }
                ]
              }
            }
          ) + "\n"
        )

        send_line(socket_path, "{\"type\":\"subscribe\",\"session_id\":\"c2\",\"payload\":{\"channel\":\"telegram\"}}\n")
        send2 = send_line(
          socket_path,
          JSON.generate(
            {
              type: "send",
              session_id: "c2",
              payload: {
                channel: "telegram",
                project_ref: "alpha",
                intent: "change",
                message: "write from c2",
                actions: [
                  {
                    id: "w2",
                    type: "write_file",
                    args: { path: "runtime/c2.txt", content: "two\n" },
                    requires_confirmation: false,
                    timeout_ms: 10_000,
                    on_failure: "abort"
                  }
                ]
              }
            }
          ) + "\n"
        )

        server_thread.join(2)

        assert_equal("ack", send1["type"])
        assert_equal("ok", send1.dig("payload", "status"))
        assert_equal("ack", send2["type"])
        assert_equal("ok", send2.dig("payload", "status"))
        assert_equal(true, File.file?(File.join(project_path, "runtime", "c1.txt")))
        assert_equal(true, File.file?(File.join(project_path, "runtime", "c2.txt")))
        assert_equal(false, File.file?(File.join(project_path, "..", "escape.txt")))
      end
    end
  end

  private

  def send_line(socket_path, line)
    socket = UNIXSocket.new(socket_path)
    socket.write(line)
    JSON.parse(socket.gets)
  ensure
    socket&.close
  end
end
