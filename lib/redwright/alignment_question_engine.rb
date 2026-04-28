# frozen_string_literal: true

require "json"

module Redwright
  class AlignmentQuestionEngine
    Turn = Struct.new(
      :status,
      :question,
      :recommendation,
      :rationale,
      :decision_node,
      :tags,
      :completion_status,
      :source,
      :finish_reason,
      keyword_init: true
    )

    SYSTEM_PROMPT = <<~TEXT
      You generate exactly one next alignment question for a software planning loop.
      Return strict JSON with exactly these keys:
      - status: one of "continue" or "ready"
      - question: non-empty string when status is "continue", empty string when status is "ready"
      - recommendation: concise recommendation string
      - rationale: concise rationale string
      - decision_node: stable semantic node string
      - tags: array of short lowercase strings
      - completion_status: one of "open" or "done"
      Do not return extra keys.
    TEXT

    def initialize(llm_client:, max_validation_attempts: 2)
      @llm_client = llm_client
      @max_validation_attempts = max_validation_attempts
    end

    def next_turn(model:, objective:, prior_turns:)
      return fallback_turn unless @llm_client&.configured?

      payload = build_payload(objective: objective, prior_turns: prior_turns)
      raw_output = nil
      @max_validation_attempts.times do
        completion = @llm_client.complete_json(
          model: model,
          system_prompt: SYSTEM_PROMPT,
          user_text: payload
        )
        raw_output = completion.content
        parsed = parse_and_validate(raw_output)
        next unless parsed

        return Turn.new(
          status: parsed.fetch("status"),
          question: parsed.fetch("question"),
          recommendation: parsed.fetch("recommendation"),
          rationale: parsed.fetch("rationale"),
          decision_node: parsed.fetch("decision_node"),
          tags: parsed.fetch("tags"),
          completion_status: parsed.fetch("completion_status"),
          source: "llm",
          finish_reason: completion.finish_reason || "stop"
        )
      end

      fallback_turn(finish_reason: "invalid_payload", source: "fallback")
    rescue StandardError => e
      fallback_turn(finish_reason: "llm_error:#{e.class}", source: "fallback")
    end

    private

    def build_payload(objective:, prior_turns:)
      lines = []
      lines << "objective: #{objective}"
      lines << "prior_turns_count: #{prior_turns.size}"
      prior_turns.each_with_index do |turn, idx|
        lines << "turn_#{idx + 1}_question: #{turn[:question]}"
        lines << "turn_#{idx + 1}_answer: #{turn[:answer]}"
      end
      lines.join("\n")
    end

    def parse_and_validate(raw_output)
      parsed = JSON.parse(raw_output)
      expected = %w[status question recommendation rationale decision_node tags completion_status]
      return nil unless parsed.is_a?(Hash)
      return nil unless parsed.keys.sort == expected.sort
      return nil unless %w[continue ready].include?(parsed["status"])
      return nil unless %w[open done].include?(parsed["completion_status"])
      return nil unless parsed["tags"].is_a?(Array) && parsed["tags"].all? { |v| v.is_a?(String) && !v.empty? }
      return nil unless parsed["recommendation"].is_a?(String)
      return nil unless parsed["rationale"].is_a?(String)
      return nil unless parsed["decision_node"].is_a?(String)

      question = parsed["question"].to_s.strip
      if parsed["status"] == "continue"
        return nil if question.empty?
      elsif !question.empty?
        return nil
      end
      parsed["question"] = question
      parsed
    rescue JSON::ParserError
      nil
    end

    def fallback_turn(finish_reason: "llm_not_configured", source: "fallback")
      Turn.new(
        status: "continue",
        question: "What is the minimal acceptance criteria for this task?",
        recommendation: "Define the smallest verifiable outcome first.",
        rationale: "A minimal target reduces ambiguity and iteration waste.",
        decision_node: "planning.acceptance_criteria",
        tags: ["scope", "acceptance"],
        completion_status: "open",
        source: source,
        finish_reason: finish_reason
      )
    end
  end
end
