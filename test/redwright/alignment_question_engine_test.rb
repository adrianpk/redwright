# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../lib", __dir__))
require "redwright/alignment_question_engine"

class AlignmentQuestionEngineTest < Minitest::Test
  FakeCompletion = Struct.new(:content, :finish_reason, keyword_init: true)

  class FakeLlmClient
    def initialize(content)
      @content = content
    end

    def configured?
      true
    end

    def complete_json(model:, system_prompt:, user_text:)
      FakeCompletion.new(content: @content, finish_reason: "stop")
    end
  end

  def test_rejects_multiple_questions_payload_and_falls_back
    raw = <<~JSON
      {"status":"continue","question":"","recommendation":"r","rationale":"r","decision_node":"n","tags":["x"],"completion_status":"open"}
    JSON
    engine = Redwright::AlignmentQuestionEngine.new(llm_client: FakeLlmClient.new(raw))
    turn = engine.next_turn(model: "gpt-5-mini", objective: "Plan this", prior_turns: [])

    assert_equal("continue", turn.status)
    refute_empty(turn.question)
    assert_equal("fallback", turn.source)
  end

  def test_accepts_valid_single_question_payload
    raw = <<~JSON
      {"status":"continue","question":"What is the acceptance criteria?","recommendation":"Define concrete checks","rationale":"Improves determinism","decision_node":"scope.acceptance","tags":["scope","acceptance"],"completion_status":"open"}
    JSON
    engine = Redwright::AlignmentQuestionEngine.new(llm_client: FakeLlmClient.new(raw))
    turn = engine.next_turn(model: "gpt-5-mini", objective: "Plan this", prior_turns: [])

    assert_equal("continue", turn.status)
    assert_equal("What is the acceptance criteria?", turn.question)
    assert_equal("llm", turn.source)
  end
end
