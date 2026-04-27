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

class TelegramRuntimeHandlerTest < Minitest::Test
  FakeTelegramClient = Struct.new(:messages) do
    def send_message(chat_id:, text:)
      self.messages ||= []
      self.messages << { chat_id: chat_id, text: text }
      { "ok" => true }
    end
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
        assert_match(/^ok$/, sent[:text].lines.first.strip)
        assert_match("project_id: #{project.id}", sent[:text])
        assert_match("workstream_id: ", sent[:text])
        assert_match("task_id: ", sent[:text])
        assert_match("state: executing", sent[:text])
      end
    end
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
    assert_match("error: project not found", client.messages.first[:text])
  end
end
