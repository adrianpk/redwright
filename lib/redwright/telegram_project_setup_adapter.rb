# frozen_string_literal: true

require "shellwords"

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
      @ticket_ids_by_chat = {}
    end

    def handle(event, trace_id:)
      command = parse_command(event.text)
      return handle_project_command(event: event, command: command, trace_id: trace_id) if command
      ticket_command = parse_ticket_command(event.text)
      return handle_ticket_command(event: event, command: ticket_command, trace_id: trace_id) if ticket_command
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

    def handle_ticket_command(event:, command:, trace_id:)
      case command[:command]
      when "list"
        list_tickets(event: event, trace_id: trace_id)
      when "pick"
        pick_ticket(event: event, trace_id: trace_id)
      when "start"
        start_ticket_execution(event: event, ticket_id: command[:ticket_id], trace_id: trace_id)
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

    def list_tickets(event:, trace_id:)
      project_id = active_project_id(event.chat_id)
      return missing_project_context_result(command: "ticket_list", trace_id: trace_id) unless project_id

      response = client.query(
        name: "GetTicketsByProject",
        payload: {"project_id" => project_id},
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "list-tickets")
      )

      Result.new(
        handled: true,
        command: "ticket_list",
        message: render_ticket_list(body: response.body, trace_id: trace_id),
        api_response: response.body
      )
    end

    def pick_ticket(event:, trace_id:)
      project_id = active_project_id(event.chat_id)
      return missing_project_context_result(command: "ticket_pick", trace_id: trace_id) unless project_id

      response = client.query(
        name: "PickNextTicket",
        payload: {"project_id" => project_id},
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "pick-ticket")
      )
      body = response.body
      ticket_id = body["ticket_id"] || body.dig("data", "ticket_id")
      @ticket_ids_by_chat[event.chat_id] = ticket_id if ticket_id

      Result.new(
        handled: true,
        command: "ticket_pick",
        message: render_ticket_pick(body: body, trace_id: trace_id),
        api_response: body
      )
    end

    def start_ticket_execution(event:, ticket_id:, trace_id:)
      response = client.command(
        name: "StartTicketExecution",
        payload: {"ticket_id" => ticket_id},
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "start-ticket-execution")
      )
      body = response.body
      remember_ticket_context(chat_id: event.chat_id, body: body)

      Result.new(
        handled: true,
        command: "ticket_start",
        message: render_ticket_execution(body: body, trace_id: trace_id),
        api_response: body
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

    def render_ticket_list(body:, trace_id:)
      tickets = body.dig("data", "tickets") || []
      lines = tickets.first(20).map do |ticket|
        "- #{ticket['id']}: #{ticket['title']} [#{ticket['column_key']}]"
      end
      body_text = lines.empty? ? "No tickets found." : lines.join("\n")
      [
        "Tickets:",
        body_text,
        "Trace: #{trace_id}"
      ].join("\n")
    end

    def render_ticket_pick(body:, trace_id:)
      ticket = body.dig("data", "ticket")
      unless ticket
        return [
          "No active ticket selected.",
          summary_from(body),
          "Trace: #{trace_id}"
        ].join("\n")
      end

      [
        "Next ticket: #{ticket['title']} (#{ticket['id']})",
        "Column: #{ticket['column_key']}",
        "Trace: #{trace_id}"
      ].join("\n")
    end

    def render_ticket_execution(body:, trace_id:)
      if body.fetch("status", "") == "error"
        return [
          "Ticket execution error: #{summary_from(body)}",
          *error_lines_from(body),
          "Trace: #{trace_id}"
        ].join("\n")
      end

      ticket = body.dig("data", "ticket") || {}
      runtime = ticket["runtime_execution"] || {}
      [
        summary_from(body),
        "Ticket: #{ticket['title']} (#{ticket['id']})",
        "Runtime: #{runtime['status'] || 'unknown'}",
        "Execution: #{runtime['execution_id'] || 'none'}",
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

    def remember_ticket_context(chat_id:, body:)
      project_id = body["project_id"] || body.dig("data", "project_id")
      ticket_id = body["ticket_id"] || body.dig("data", "ticket_id")
      @project_ids_by_chat[chat_id] = project_id if project_id
      @ticket_ids_by_chat[chat_id] = ticket_id if ticket_id
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

    def active_project_id(chat_id)
      @project_ids_by_chat[chat_id]
    end

    def parse_command(text)
      raw = text.to_s.strip
      return nil unless raw.start_with?("/project")

      parts = shellsplit(raw)
      return nil unless parts.first.to_s.downcase == "/project"
      action = parts[1].to_s.downcase

      return {command: "new_missing"} if action == "new" && parts[2].to_s.empty?
      return {command: "new", project_name: parts[2]} if action == "new" && valid_project_name?(parts[2])
      return {command: "list"} if raw.match?(%r{\A/project\s+list\s*\z}i)
      return {command: "where"} if raw.match?(%r{\A/project\s+where\s*\z}i)

      nil
    end

    def shellsplit(raw)
      Shellwords.split(raw)
    rescue ArgumentError
      raw.split(/\s+/)
    end

    def valid_project_name?(value)
      value.to_s.match?(%r{\A[a-zA-Z0-9._\-]+\z})
    end

    def parse_ticket_command(text)
      raw = text.to_s.strip
      return nil unless raw.start_with?("/ticket")
      return {command: "list"} if raw.match?(%r{\A/ticket\s+list\s*\z}i)
      return {command: "pick"} if raw.match?(%r{\A/ticket\s+pick\s*\z}i)

      start_match = raw.match(%r{\A/ticket\s+start\s+([a-zA-Z0-9._\-]+)\s*\z}i)
      return {command: "start", ticket_id: start_match[1]} if start_match

      nil
    end

    def missing_project_context_result(command:, trace_id:)
      Result.new(
        handled: true,
        command: command,
        message: "No active Rails project for ticket command.\nTrace: #{trace_id}",
        api_response: nil
      )
    end

    def slash?(text)
      text.to_s.strip.start_with?("/")
    end

    def actor_identifier_for(event)
      user = if event.respond_to?(:user_id)
               event.user_id
             elsif event.respond_to?(:sender_id)
               event.sender_id
             end
      user = event.username if user.nil? && event.respond_to?(:username)
      user ||= "unknown"
      "telegram:chat:#{event.chat_id}:user:#{user}"
    end

    def request_id_for(event, suffix)
      message_id = if event.respond_to?(:update_id)
                     event.update_id
                   elsif event.respond_to?(:external_message_id)
                     event.external_message_id
                   end
      message_id ||= "unknown"
      "telegram-#{event.chat_id}-#{message_id}-#{suffix}"
    end
  end
end
