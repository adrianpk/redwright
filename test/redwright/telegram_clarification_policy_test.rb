# frozen_string_literal: true

require "stringio"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/telegram_clarification_policy"

class TelegramClarificationPolicyTest < Minitest::Test
  FakeSession = Struct.new(:id, :gap_type, :payload, keyword_init: true)

  class FakeStore
    attr_reader :calls

    def initialize(session)
      @session = session
      @calls = []
    end

    def get_open(chat_id:, workstream_id: nil)
      _ = chat_id
      _ = workstream_id
      @session
    end

    def cancel_open(chat_id:, workstream_id: nil)
      @calls << { chat_id: chat_id, workstream_id: workstream_id }
    end
  end

  def test_confirmation_reply_only
    policy = Redwright::TelegramClarificationPolicy.new(clarification_session_store: nil, err: StringIO.new)
    assert_equal(true, policy.confirmation_reply_only?("yes"))
    assert_equal(false, policy.confirmation_reply_only?("build feature"))
  end

  def test_continue_semantic_phrase_match
    policy = Redwright::TelegramClarificationPolicy.new(clarification_session_store: nil, err: StringIO.new)
    assert_equal(true, policy.continue_with_current_context_semantic?("continua con lo que tengas"))
    assert_equal(false, policy.continue_with_current_context_semantic?("necesito más datos"))
  end

  def test_cancel_open_scope_chat_and_task
    store = FakeStore.new(nil)
    policy = Redwright::TelegramClarificationPolicy.new(clarification_session_store: store, err: StringIO.new)

    policy.cancel_open(chat_id: 11, workstream_id: "ws-1", scope: "chat")
    policy.cancel_open(chat_id: 11, workstream_id: "ws-1", scope: "task")

    assert_equal({ chat_id: 11, workstream_id: nil }, store.calls[0])
    assert_equal({ chat_id: 11, workstream_id: "ws-1" }, store.calls[1])
  end

  def test_active_planner_gap_returns_open_session
    session = FakeSession.new(id: "s1", gap_type: "planner_gap", payload: {})
    store = FakeStore.new(session)
    policy = Redwright::TelegramClarificationPolicy.new(clarification_session_store: store, err: StringIO.new)

    assert_equal(session, policy.active_planner_gap(chat_id: 22, workstream_id: "ws-2"))
  end
end
