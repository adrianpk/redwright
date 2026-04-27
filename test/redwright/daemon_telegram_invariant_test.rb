# frozen_string_literal: true

require "tmpdir"
require "stringio"
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

class DaemonTelegramInvariantTest < Minitest::Test
  FakeTelegramClient = Struct.new(:messages) do
    def send_message(chat_id:, text:)
      self.messages ||= []
      self.messages << { chat_id: chat_id, text: text }
      { "ok" => true }
    end
  end

  def test_event_to_runtime_action_contract_is_stable
    Dir.mktmpdir("redwright-daemon-telegram-invariant-") do |dir|
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
        event = Redwright::TelegramEvent.new(update_id: 1, chat_id: 123, user_id: 777, username: "tester", text: "implement smoke")
        client = FakeTelegramClient.new([])
        handler = Redwright::TelegramRuntimeHandler.new(
          flow: flow,
          telegram_client: client,
          out: StringIO.new,
          err: StringIO.new,
          blocked_retry_attempts: 1
        )

        handler.handle(event)

        assert_equal(1, client.messages.size)
        text = client.messages.first[:text]
        assert_match("project_id: #{project.id}", text)
        assert_match("workstream_id: ", text)
        assert_match("task_id: ", text)
        assert_match("state: executing", text)
        tasks = task_store.list
        assert_equal(1, tasks.size)
        assert_equal("implement smoke", tasks.first.description)
      end
    end
  end
end
