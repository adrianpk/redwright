# frozen_string_literal: true

require "json"

require_relative "llm/request_engine"
require_relative "llm/trace_recorder"

module Redwright
  class ProjectSetupPromptRenderer
    SYSTEM_PROMPT = <<~TEXT
      You render exactly one Telegram message for a software project setup conversation.
      Rails has already selected the next semantic setup slot; do not change the slot.
      Match the language of the user's latest message when it is clear.
      Ask exactly one concise question.
      Mention available controls only when useful: /skip, /done, /cancel.
      Do not expose internal state names, session ids, trace ids, validators, or JSON.
      Do not use colon shortcode tokens such as :gear: or :keyboard:.
      Return strict JSON with exactly one key: message.
    TEXT

    def initialize(llm_client: nil, model: "none", debug: false, trace_recorder: LLM::TraceRecorder.new)
      @llm_client = llm_client
      @model = model.to_s
      @debug = debug == true
      @request_engine = LLM::RequestEngine.new(llm_client: llm_client)
      @trace_recorder = trace_recorder
    end

    def render(body:, user_text:, trace_id:)
      payload = merged_payload(body)
      return render_error(payload: payload, trace_id: trace_id) if payload["status"].to_s == "error"
      return render_completion(payload: payload, trace_id: trace_id) if terminal_completed?(payload)

      intent = payload["next_prompt_intent"]
      if setup_slot_intent?(intent)
        message = render_prompt_via_llm(payload: payload, intent: intent, user_text: user_text, trace_id: trace_id)
        return with_debug(message, trace_id: trace_id)
      end
      if generic_question_intent?(intent)
        return with_debug(fallback_prompt(payload: payload, intent: intent), trace_id: trace_id)
      end

      with_debug(payload["summary"].to_s.empty? ? "Project setup is waiting for more context." : payload["summary"], trace_id: trace_id)
    end

    private

    def merged_payload(body)
      source = body.is_a?(Hash) ? body : {}
      data = source["data"].is_a?(Hash) ? source["data"] : {}
      source.merge(data)
    end

    def render_prompt_via_llm(payload:, intent:, user_text:, trace_id:)
      return fallback_prompt(payload: payload, intent: intent) unless llm_configured?

      llm_payload = JSON.generate(
        {
          setup_summary: payload["summary"].to_s,
          next_prompt_intent: intent,
          setup_context: payload["setup_context"] || {},
          user_text: user_text.to_s
        }
      )
      llm_call_id = @trace_recorder.record_request(
        model_role: "non_coding",
        provider: provider_name,
        model: @model,
        model_alias: @model,
        action: "project_setup_prompt_render",
        payload_bytes: llm_payload.bytesize,
        system_prompt: SYSTEM_PROMPT,
        user_text: llm_payload,
        trace_id: trace_id,
        project_id: payload["project_id"] || payload.dig("project", "id"),
        session_id: payload["session_id"],
        source_channel: "project_setup",
        context_summary: payload["summary"].to_s,
        context_bytes: JSON.generate(payload["setup_context"] || {}).bytesize,
        context_sections: ["setup_summary", "next_prompt_intent", "setup_context", "user_text"]
      )
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = @request_engine.generate_structured_message(
        model: @model,
        model_role: "non_coding",
        provider: provider_name,
        action: "project_setup_prompt_render",
        system_prompt: SYSTEM_PROMPT,
        user_text: llm_payload,
        output_contract: {"required_fields" => ["message"], "rendered_text_field" => "message"},
        context_sections: ["setup_summary", "next_prompt_intent", "setup_context", "user_text"],
        trace_metadata: {
          trace_id: trace_id,
          project_id: payload["project_id"] || payload.dig("project", "id"),
          session_id: payload["session_id"],
          source_channel: "project_setup"
        }
      )
      elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).to_i
      message = response.rendered_text.to_s.strip
      @trace_recorder.record_response(
        status: response.ok? ? "ok" : "fallback",
        llm_call_id: llm_call_id,
        latency_ms: elapsed_ms,
        output_bytes: response.raw_response_ref.to_s.bytesize,
        finish_reason: response.provider_metadata[:finish_reason],
        decision_source: response.ok? ? "llm" : response.status,
        parsed_message: message,
        raw_output: response.raw_response_ref,
        error: response.ok? ? nil : response.warnings.join("; "),
        trace_id: trace_id,
        project_id: payload["project_id"] || payload.dig("project", "id"),
        session_id: payload["session_id"],
        source_channel: "project_setup",
        action: "project_setup_prompt_render",
        model_role: "non_coding",
        provider: provider_name,
        model: @model,
        model_alias: @model,
        payload_bytes: llm_payload.bytesize
      )
      return fallback_prompt(payload: payload, intent: intent) unless response.ok?

      sanitize_message(message.empty? ? fallback_prompt(payload: payload, intent: intent) : message)
    rescue StandardError => e
      elapsed_ms = defined?(started_at) && started_at ? ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).to_i : 0
      @trace_recorder.record_response(
        status: "fallback",
        llm_call_id: llm_call_id,
        latency_ms: elapsed_ms,
        output_bytes: 0,
        decision_source: "error",
        raw_output: e.message,
        error: e.message,
        trace_id: trace_id,
        project_id: payload["project_id"] || payload.dig("project", "id"),
        session_id: payload["session_id"],
        source_channel: "project_setup",
        action: "project_setup_prompt_render",
        model_role: "non_coding",
        provider: provider_name,
        model: @model,
        model_alias: @model,
        payload_bytes: llm_payload.bytesize
      )
      fallback_prompt(payload: payload, intent: intent)
    end

    def render_error(payload:, trace_id:)
      lines = ["Project setup error: #{payload["summary"] || "Unable to continue project setup."}"]
      if payload["errors"].is_a?(Array)
        payload["errors"].first(3).each do |error|
          lines << "- #{error["code"] || error[:code]}: #{error["message"] || error[:message]}"
        end
      end
      with_debug(sanitize_message(lines.join("\n")), trace_id: trace_id)
    end

    def render_completion(payload:, trace_id:)
      project = payload["project"].is_a?(Hash) ? payload["project"] : {}
      project_name = project["name"].to_s
      project_id = payload["project_id"] || project["id"]
      label = project_name.empty? ? "project #{project_id}" : "#{project_name} (#{project_id})"
      lines = ["Project setup is complete. I created #{label}."]
      workspace = payload["workspace"].is_a?(Hash) ? payload["workspace"] : {}
      workspace_path = workspace["relative_path"].to_s.strip
      workspace_path = workspace["path"].to_s.strip if workspace_path.empty?
      lines << "Workspace: #{workspace_path}" unless workspace_path.empty?
      materialization_status = workspace["materialization_status"].to_s.strip
      initial_status = workspace["initial_implementation_status"].to_s.strip
      validation_status = validation_status_from(workspace)
      lines << "Materialization: #{materialization_status.tr("_", " ")}." unless materialization_status.empty?
      lines << "Initial implementation: #{initial_status.tr("_", " ")}." unless initial_status.empty?
      lines << "Runnable: #{workspace["runnable"] == true ? "yes" : "no"}." if workspace.key?("runnable")
      lines << "Validation: #{validation_status.tr("_", " ")}." unless validation_status.empty?
      lines << "Use /project where to inspect the active project."
      with_debug(sanitize_message(lines.join("\n")), trace_id: trace_id)
    end

    def validation_status_from(workspace)
      validation_status = workspace["validation_status"].to_s.strip
      return validation_status unless validation_status.empty?

      validation = workspace["validation"].is_a?(Hash) ? workspace["validation"] : {}
      validation["status"].to_s.strip
    end

    def fallback_prompt(payload:, intent:)
      understood = understood_context(payload)
      question = intent_question_text(intent)
      controls = fallback_controls(intent)
      sanitize_message([understood, question, controls].compact.join("\n"))
    end

    def intent_question_text(intent)
      metadata_question = intent.dig("metadata", "question_text").to_s.strip
      return metadata_question unless metadata_question.empty?

      fallback_question(intent["slot"])
    end

    def understood_context(payload)
      slots = payload.dig("setup_context", "slots")
      return nil unless slots.is_a?(Hash)

      name = slots.dig("project_name", "value").to_s
      description = slots.dig("description", "value").to_s
      return nil if name.empty? && description.empty?

      parts = []
      parts << "Project: #{name}" unless name.empty?
      parts << "Description: #{description}" unless description.empty?
      parts.join("\n")
    end

    def fallback_question(slot)
      case slot.to_s
      when "project_name"
        "What should I call this project?"
      when "description"
        "What should this project do?"
      when "project_type"
        "What type of project should this be: CLI, API, web app, library, worker, or something else?"
      when "language_runtime"
        "What primary language or runtime should this project use?"
      when "stack"
        "What stack should I assume for this project?"
      when "framework"
        "What framework should this project use, if any?"
      when "libraries"
        "What main libraries or services should I include or expect?"
      when "repository"
        "Do you want to attach a repository URL or owner/repo now?"
      else
        "What else should I know before creating this project?"
      end
    end

    def fallback_controls(intent)
      kind = intent["kind"].to_s
      slot = intent["slot"].to_s
      return "Reply with the repository reference or use /cancel to stop setup." if kind == "repository_clarification_question"
      return "Reply with your answer or use /cancel to stop setup." if kind == "guided_alignment_question"
      return "Use /cancel to stop setup." if slot.to_s == "project_name"

      "Reply with an answer, /skip to skip this slot, /done to create the project with defaults, or /cancel to stop setup."
    end

    def setup_slot_intent?(intent)
      intent.is_a?(Hash) && intent["kind"].to_s == "setup_slot_question" && !intent["slot"].to_s.empty?
    end

    def generic_question_intent?(intent)
      return false unless intent.is_a?(Hash)

      %w[guided_alignment_question repository_clarification_question].include?(intent["kind"].to_s)
    end

    def terminal_completed?(payload)
      payload["state"].to_s == "completed" || payload["status"].to_s == "completed"
    end

    def llm_configured?
      @llm_client&.configured? && !@model.empty? && @model != "none"
    end

    def provider_name
      provider = @model.split("/", 2).first.to_s
      provider.empty? ? "unknown" : provider
    end

    def with_debug(message, trace_id:)
      clean = sanitize_message(message)
      return clean unless @debug

      [clean, "Trace: #{trace_id}"].join("\n")
    end

    def sanitize_message(message)
      message.to_s.gsub(/:[a-z0-9_+-]+:/i, "").gsub(/[ \t]{2,}/, " ").strip
    end
  end
end
