# frozen_string_literal: true

require "securerandom"

module Redwright
  module Trace
    module_function

    def enabled?
      value = ENV.fetch("REDWRIGHT_TRACE", "").strip.downcase
      value == "1" || value == "true" || value == "yes" || value == "on"
    end

    def current_trace_id
      Thread.current[:redwright_trace_id]
    end

    def with_trace_id(trace_id = nil)
      previous = current_trace_id
      Thread.current[:redwright_trace_id] = trace_id || generate_trace_id
      yield
    ensure
      Thread.current[:redwright_trace_id] = previous
    end

    def banner(title, fields = {})
      return unless enabled?

      line = "=" * 52
      $stdout.puts(line)
      $stdout.puts(title)
      fields.each { |key, value| $stdout.puts("#{key}: #{value}") }
      $stdout.puts(line)
    end

    def sqlite(op:, table:, detail: nil)
      banner("SQLITE TRACE", {
        trace_id: current_trace_id || "none",
        op: op,
        table: table,
        detail: detail
      }.compact)
    end

    def llm_request(role:, provider:, model:, action:, payload_bytes:, system_prompt: nil, user_text: nil)
      banner("LLM REQUEST", {
        trace_id: current_trace_id || "none",
        model_role: role,
        provider: provider,
        model: model,
        action: action,
        payload_bytes: payload_bytes,
        system_prompt: system_prompt,
        user_text: user_text
      }.compact)
    end

    def llm_response(
      status:,
      latency_ms:,
      output_bytes:,
      finish_reason: nil,
      raw_output: nil,
      parsed_intent: nil,
      parsed_message: nil,
      decision_source: nil
    )
      banner("LLM RESPONSE", {
        trace_id: current_trace_id || "none",
        status: status,
        latency_ms: latency_ms,
        output_bytes: output_bytes,
        finish_reason: finish_reason,
        decision_source: decision_source,
        parsed_intent: parsed_intent,
        parsed_message: parsed_message,
        raw_output: raw_output
      }.compact)
    end

    def generate_trace_id
      "trc-#{SecureRandom.hex(4)}"
    end
  end
end
