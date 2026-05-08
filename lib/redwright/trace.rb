# frozen_string_literal: true

require "json"
require "securerandom"
require_relative "llm_trace_file_writer"

module Redwright
  module Trace
    module_function

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
      line = "=" * 52
      $stdout.puts(line)
      $stdout.puts(title)
      fields.each { |key, value| $stdout.puts("#{key}: #{value}") }
      $stdout.puts(line)
    end

    def sqlite(op:, table:, detail: nil)
      return unless sqlite_enabled?

      banner("SQLITE TRACE", {
        trace_id: current_trace_id || "none",
        op: op,
        table: table,
        detail: detail
      }.compact)
    end

    def llm_request(
      role:,
      provider:,
      model:,
      action:,
      payload_bytes:,
      llm_call_id: nil,
      trace_id: nil,
      model_alias: nil,
      resolved_model: nil,
      system_prompt: nil,
      user_text: nil,
      project_id: nil,
      project_ref: nil,
      project_root: nil,
      ticket_id: nil,
      session_id: nil,
      source_channel: nil,
      actor_identifier: nil,
      context_summary: nil,
      context_bytes: nil,
      context_sections: nil
    )
      llm_call_id ||= generate_llm_call_id
      return unless llm_foreground_enabled? || llm_file_enabled?

      if llm_foreground_enabled?
        banner("LLM REQUEST", {
          trace_id: trace_id || current_trace_id || "none",
          llm_call_id: llm_call_id,
          model_role: role,
          provider: provider,
          model: model,
          model_alias: model_alias,
          resolved_model: resolved_model,
          action: action,
          payload_bytes: payload_bytes,
          system_prompt: system_prompt,
          user_text: user_text
        }.compact)
      end
      write_llm_file_event(
        event: "llm_request",
        llm_call_id: llm_call_id,
        trace_id: trace_id || current_trace_id,
        project_id: project_id,
        project_ref: project_ref,
        project_root: project_root,
        ticket_id: ticket_id,
        session_id: session_id,
        source_channel: source_channel,
        actor_identifier: actor_identifier,
        model_role: role,
        provider: provider,
        model: model,
        model_alias: model_alias,
        resolved_model: resolved_model,
        action: action,
        payload_bytes: payload_bytes,
        system_prompt: include_system_prompt? ? system_prompt : nil,
        user_text: include_user_text? ? user_text : nil,
        context_summary: context_summary,
        context_bytes: context_bytes,
        context_sections: context_sections
      )
      llm_call_id
    end

    def llm_response(
      status:,
      latency_ms:,
      output_bytes:,
      llm_call_id: nil,
      trace_id: nil,
      finish_reason: nil,
      raw_output: nil,
      parsed_intent: nil,
      parsed_message: nil,
      parsed_fields: nil,
      decision_source: nil,
      error: nil,
      project_id: nil,
      project_ref: nil,
      project_root: nil,
      ticket_id: nil,
      session_id: nil,
      source_channel: nil,
      actor_identifier: nil,
      action: nil,
      role: nil,
      provider: nil,
      model: nil,
      model_alias: nil,
      resolved_model: nil,
      payload_bytes: nil,
      warnings: nil,
      diagnostics: nil
    )
      llm_call_id ||= generate_llm_call_id
      return unless llm_foreground_enabled? || llm_file_enabled?

      if llm_foreground_enabled?
        banner("LLM RESPONSE", {
          trace_id: trace_id || current_trace_id || "none",
          llm_call_id: llm_call_id,
          status: status,
          latency_ms: latency_ms,
          output_bytes: output_bytes,
          finish_reason: finish_reason,
          decision_source: decision_source,
          parsed_intent: parsed_intent,
          parsed_message: parsed_message,
          warnings: Array(warnings).empty? ? nil : Array(warnings).join(" | "),
          raw_output: raw_output
        }.compact)
      end
      write_llm_file_event(
        event: "llm_response",
        llm_call_id: llm_call_id,
        trace_id: trace_id || current_trace_id,
        project_id: project_id,
        project_ref: project_ref,
        project_root: project_root,
        ticket_id: ticket_id,
        session_id: session_id,
        source_channel: source_channel,
        actor_identifier: actor_identifier,
        model_role: role,
        provider: provider,
        model: model,
        model_alias: model_alias,
        resolved_model: resolved_model,
        action: action,
        payload_bytes: payload_bytes,
        status: status,
        latency_ms: latency_ms,
        output_bytes: output_bytes,
        finish_reason: finish_reason,
        raw_output: include_raw_output? ? raw_output : nil,
        parsed_intent: parsed_intent,
        parsed_message: parsed_message,
        parsed_fields: parsed_fields,
        decision_source: decision_source,
        error: error,
        warnings: warnings,
        diagnostics: diagnostics
      )
      llm_call_id
    end

    def runtime(fields = {})
      return unless runtime_enabled?

      banner("RUNTIME TRACE", fields)
    end

    def generate_trace_id
      "trc-#{SecureRandom.hex(4)}"
    end

    def generate_llm_call_id
      "llm-#{SecureRandom.hex(6)}"
    end

    def configure(tracing:)
      @llm_file_config = tracing&.llm_file
      @llm_trace_writer = nil
      @trace_warnings = {}
    end

    def reset_configuration!
      @llm_file_config = nil
      @llm_trace_writer = nil
      @trace_warnings = {}
    end

    def llm_enabled?
      llm_foreground_enabled? || llm_file_enabled?
    end

    def llm_foreground_enabled?
      global_enabled? || truthy_env?("REDWRIGHT_TRACE_LLM")
    end

    def sqlite_enabled?
      global_enabled? || truthy_env?("REDWRIGHT_TRACE_SQLITE")
    end

    def runtime_enabled?
      global_enabled? || truthy_env?("REDWRIGHT_TRACE_RUNTIME")
    end

    def global_enabled?
      truthy_env?("REDWRIGHT_TRACE")
    end

    def llm_file_enabled?
      @llm_file_config && @llm_file_config.enabled == true
    end

    def include_payloads?
      llm_file_enabled? && @llm_file_config.include_payloads == true
    end

    def include_system_prompt?
      include_payloads? && @llm_file_config.include_system_prompt == true
    end

    def include_user_text?
      include_payloads? && @llm_file_config.include_user_text == true
    end

    def include_raw_output?
      include_payloads? && @llm_file_config.include_raw_output == true
    end

    def llm_trace_writer
      return nil unless llm_file_enabled?

      @llm_trace_writer ||= LlmTraceFileWriter.new(config: @llm_file_config)
    end

    def write_llm_file_event(**event)
      return unless llm_file_enabled?

      llm_trace_writer.write(event)
    rescue StandardError => e
      warn_once("llm trace file write failed: #{e.message}")
    end

    def warn_once(message)
      @trace_warnings ||= {}
      return if @trace_warnings[message]

      @trace_warnings[message] = true
      $stderr.puts(message)
    end

    def truthy_env?(name)
      value = ENV.fetch(name, "").strip.downcase
      value == "1" || value == "true" || value == "yes" || value == "on"
    end
    private_class_method :truthy_env?
  end
end
