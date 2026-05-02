# frozen_string_literal: true

module Redwright
  class TelegramProjectSetupAdapter
    Result = Struct.new(:handled, :command, :message, :api_response, keyword_init: true) do
      def handled?
        handled == true
      end
    end

    TERMINAL_STATES = %w[completed cancelled failed needs_reconciliation].freeze

    def initialize(client:)
      @client = client
      @session_ids_by_chat = {}
      @project_ids_by_chat = {}
    end

    def handle(event, trace_id:)
      command = parse_command(event.text)
      return handle_project_command(event: event, command: command, trace_id: trace_id) if command
      return advance_active_session(event: event, trace_id: trace_id) if active_session_id(event.chat_id) && !slash?(event.text)

      Result.new(handled: false)
    end

    private

    attr_reader :client

    def handle_project_command(event:, command:, trace_id:)
      case command[:command]
      when "new"
        start_project_setup(event: event, project_name: command[:project_name], trace_id: trace_id)
      when "new_missing"
        Result.new(
          handled: true,
          command: "project_new_missing",
          message: "Please provide a project name: /project new <name>.\nTrace: #{trace_id}",
          api_response: nil
        )
      when "list"
        list_projects(event: event, trace_id: trace_id)
      when "where"
        current_project_context(event: event, trace_id: trace_id)
      else
        Result.new(handled: false)
      end
    end

    def start_project_setup(event:, project_name:, trace_id:)
      request_id = request_id_for(event, "start-project-setup")
      response = client.command(
        name: "StartProjectSetup",
        payload: {
          "project_name" => project_name,
          "directory_name" => project_name,
          "repository_input" => project_name,
          "guided_alignment" => true
        },
        actor_identifier: actor_identifier_for(event),
        request_id: request_id
      )
      body = response.body
      remember_context(chat_id: event.chat_id, body: body)

      Result.new(
        handled: true,
        command: "project_new",
        message: render_setup_response(body: body, trace_id: trace_id),
        api_response: body
      )
    end

    def advance_active_session(event:, trace_id:)
      session_id = active_session_id(event.chat_id)
      response = client.command(
        name: "AdvanceProjectSetup",
        payload: {
          "session_id" => session_id,
          "answer" => event.text.to_s,
          "normalized_fields" => {}
        },
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "advance-project-setup")
      )
      body = response.body
      remember_context(chat_id: event.chat_id, body: body)

      Result.new(
        handled: true,
        command: "project_setup_advance",
        message: render_setup_response(body: body, trace_id: trace_id),
        api_response: body
      )
    end

    def list_projects(event:, trace_id:)
      response = client.query(
        name: "ListProjects",
        payload: {},
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "list-projects")
      )

      Result.new(
        handled: true,
        command: "project_list",
        message: render_project_list(body: response.body, trace_id: trace_id),
        api_response: response.body
      )
    end

    def current_project_context(event:, trace_id:)
      session_id = active_session_id(event.chat_id)
      if session_id
        response = client.query(
          name: "GetProjectSetupSession",
          payload: {"session_id" => session_id},
          actor_identifier: actor_identifier_for(event),
          request_id: request_id_for(event, "project-setup-status")
        )
        body = response.body
        remember_context(chat_id: event.chat_id, body: body)
        return Result.new(
          handled: true,
          command: "project_where",
          message: render_setup_response(body: body, trace_id: trace_id),
          api_response: body
        )
      end

      project_id = @project_ids_by_chat[event.chat_id]
      unless project_id
        return Result.new(
          handled: true,
          command: "project_where",
          message: "No active Rails project setup session or project for this chat.\nTrace: #{trace_id}",
          api_response: nil
        )
      end

      response = client.query(
        name: "GetProject",
        payload: {"project_id" => project_id},
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "get-project")
      )
      Result.new(
        handled: true,
        command: "project_where",
        message: render_project(body: response.body, trace_id: trace_id),
        api_response: response.body
      )
    end

    def render_setup_response(body:, trace_id:)
      if body.fetch("status", "") == "error"
        return [
          "Project setup error: #{summary_from(body)}",
          *error_lines_from(body),
          "Trace: #{trace_id}"
        ].join("\n")
      end

      parts = [
        summary_from(body),
        "State: #{body['state'] || body.dig('data', 'state') || 'unknown'}"
      ]
      session_id = body["session_id"] || body.dig("data", "session_id")
      project_id = body["project_id"] || body.dig("data", "project_id")
      next_prompt = body["next_prompt"] || body.dig("data", "next_prompt")
      parts << "Session: #{session_id}" if session_id
      parts << "Project: #{project_id}" if project_id
      parts << "Next: #{next_prompt}" unless next_prompt.to_s.empty?
      parts << "Trace: #{trace_id}"
      parts.join("\n")
    end

    def render_project_list(body:, trace_id:)
      projects = body.dig("data", "projects") || []
      lines = projects.first(20).map do |project|
        "- #{project['name']} (#{project['id']})"
      end
      body_text = lines.empty? ? "No projects found." : lines.join("\n")
      [
        "Projects:",
        body_text,
        "Trace: #{trace_id}"
      ].join("\n")
    end

    def render_project(body:, trace_id:)
      project = body.dig("data", "project") || {}
      if project.empty?
        return [
          "Project lookup failed: #{summary_from(body)}",
          "Trace: #{trace_id}"
        ].join("\n")
      end

      [
        "Active Rails project: #{project['name']} (#{project['id']})",
        "Repository: #{project['repo_url']}",
        "Trace: #{trace_id}"
      ].join("\n")
    end

    def remember_context(chat_id:, body:)
      session_id = body["session_id"] || body.dig("data", "session_id")
      project_id = body["project_id"] || body.dig("data", "project_id")
      state = body["state"] || body.dig("data", "state")

      @project_ids_by_chat[chat_id] = project_id if project_id
      if session_id && !TERMINAL_STATES.include?(state.to_s)
        @session_ids_by_chat[chat_id] = session_id
      elsif TERMINAL_STATES.include?(state.to_s)
        @session_ids_by_chat.delete(chat_id)
      end
    end

    def summary_from(body)
      body["summary"] || body.dig("data", "summary") || "No summary returned."
    end

    def error_lines_from(body)
      errors = body["errors"] || []
      errors.first(3).map do |error|
        "- #{error['code'] || error[:code]}: #{error['message'] || error[:message]}"
      end
    end

    def active_session_id(chat_id)
      @session_ids_by_chat[chat_id]
    end

    def parse_command(text)
      raw = text.to_s.strip
      return nil unless raw.start_with?("/project")
      return {command: "new_missing"} if raw.match?(%r{\A/project\s+new\s*\z}i)

      new_match = raw.match(%r{\A/project\s+new\s+([a-zA-Z0-9._\-]+)\s*\z}i)
      return {command: "new", project_name: new_match[1]} if new_match
      return {command: "list"} if raw.match?(%r{\A/project\s+list\s*\z}i)
      return {command: "where"} if raw.match?(%r{\A/project\s+where\s*\z}i)

      nil
    end

    def slash?(text)
      text.to_s.strip.start_with?("/")
    end

    def actor_identifier_for(event)
      user = event.user_id || event.username || "unknown"
      "telegram:chat:#{event.chat_id}:user:#{user}"
    end

    def request_id_for(event, suffix)
      "telegram-#{event.chat_id}-#{event.update_id}-#{suffix}"
    end
  end
end
