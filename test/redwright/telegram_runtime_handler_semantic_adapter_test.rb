# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/telegram_runtime_handler"

class TelegramRuntimeHandlerSemanticAdapterTest < Minitest::Test
  Event = Struct.new(:chat_id, :text)

  def test_uses_semantic_adapter_before_flow_execution
    flow = Object.new
    flow.define_singleton_method(:process) { raise "flow should not run" }

    client = Class.new do
      attr_reader :sent
      def initialize
        @sent = []
      end

      def send_message(chat_id:, text:)
        @sent << { chat_id: chat_id, text: text }
      end

      def send_chat_action(chat_id:, action:)
      end
    end.new

    resolver = Struct.new(:resolved, :question, :project_path, :project_ref, :workstream_id).new(
      true,
      nil,
      Dir.pwd,
      "project-1",
      "ws-1"
    )
    context_resolver = Object.new
    context_resolver.define_singleton_method(:resolve) { |_event| resolver }

    semantic_adapter = Object.new
    semantic_adapter.define_singleton_method(:dispatch) do |text:, runtime:, actor_id:|
      Struct.new(:handled, :status, :message).new(true, "ok", "semantic-ok")
    end

    handler = Redwright::TelegramRuntimeHandler.new(
      flow: flow,
      telegram_client: client,
      out: StringIO.new,
      err: StringIO.new,
      context_resolver: context_resolver,
      blocked_retry_attempts: 0,
      semantic_adapter: semantic_adapter
    )

    handler.handle(Event.new(44, "/factory status"))

    assert_equal("semantic-ok", client.sent.last[:text])
  end
end
