# frozen_string_literal: true

module Redwright
  class TelegramClarificationPolicy
    def initialize(clarification_session_store:, err:)
      @clarification_session_store = clarification_session_store
      @err = err
    end

    def cancel_open(chat_id:, workstream_id:, scope:)
      return unless @clarification_session_store

      if scope == "chat"
        @clarification_session_store.cancel_open(chat_id: chat_id)
      else
        @clarification_session_store.cancel_open(chat_id: chat_id, workstream_id: workstream_id)
      end
    rescue StandardError => e
      @err.puts("clarification cancel failed chat=#{chat_id}: #{e.message}")
    end

    def active_planner_gap(chat_id:, workstream_id:)
      pending = @clarification_session_store&.get_open(chat_id: chat_id, workstream_id: workstream_id)
      pending ||= @clarification_session_store&.get_open(chat_id: chat_id)
      pending
    end

    def confirmation_reply_only?(text)
      normalized = text.to_s.strip.downcase
      return false if normalized.empty?

      %w[yes y si sí no n nope].include?(normalized)
    end

    def continue_with_current_context_semantic?(text)
      normalized = text.to_s.strip.downcase
      return false if normalized.empty?

      phrases = [
        "continue",
        "continue with current context",
        "continue with what you have",
        "proceed with current context",
        "no more questions continue",
        "no more questions. continue",
        "no more questions, continue",
        "stop asking and continue",
        "stop asking questions and continue",
        "continua",
        "continua con lo que tengas",
        "no mas preguntas continua",
        "no más preguntas continua",
        "no mas preguntas. continua",
        "no más preguntas. continua",
        "para con las preguntas y continua",
        "para con las preguntas y continua implementando",
        "segui con lo que tenes",
        "sigue con lo que tengas"
      ]
      phrases.any? { |phrase| normalized == phrase }
    end
  end
end
