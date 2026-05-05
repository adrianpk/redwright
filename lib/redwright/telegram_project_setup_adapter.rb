# frozen_string_literal: true

require "shellwords"

require_relative "project_setup_prompt_renderer"

module Redwright
  class TelegramProjectSetupAdapter
    Result = Struct.new(:handled, :command, :message, :api_response, keyword_init: true) do
      def handled?
        handled == true
      end
    end

    TERMINAL_STATES = %w[completed cancelled failed needs_reconciliation].freeze

    def initialize(client:, prompt_renderer: ProjectSetupPromptRenderer.new)
      @client = client
      @prompt_renderer = prompt_renderer
      @session_ids_by_chat = {}
      @project_ids_by_chat = {}
      @ticket_ids_by_chat = {}
      @quiz_contexts_by_chat = {}
    end

    def handles_event?(event)
      return true if active_session_id(event.chat_id) && setup_control_command?(event.text)
      return true if active_quiz_context(event.chat_id) && quiz_control_or_answer?(event.text)

      return true if parse_command(event.text)
      return true if parse_ticket_command(event.text)
      return true if parse_quiz_command(event.text)
      return true if active_session_id(event.chat_id) && !slash?(event.text)

      false
    end

    def handle(event, trace_id:)
      return advance_active_session(event: event, trace_id: trace_id) if active_session_id(event.chat_id) && setup_control_command?(event.text)
      return advance_active_quiz(event: event, trace_id: trace_id) if active_quiz_context(event.chat_id) && quiz_control_or_answer?(event.text)

      command = parse_command(event.text)
      return handle_project_command(event: event, command: command, trace_id: trace_id) if command
      ticket_command = parse_ticket_command(event.text)
      return handle_ticket_command(event: event, command: ticket_command, trace_id: trace_id) if ticket_command
      quiz_command = parse_quiz_command(event.text)
      return handle_quiz_command(event: event, command: quiz_command, trace_id: trace_id) if quiz_command
      return advance_active_session(event: event, trace_id: trace_id) if active_session_id(event.chat_id) && !slash?(event.text)

      Result.new(handled: false)
    end

    private

    attr_reader :client

    def handle_project_command(event:, command:, trace_id:)
      case command[:command]
      when "new"
        start_project_setup(
          event: event,
          project_name: command[:project_name],
          description: command[:description],
          repository_input: command[:repository_input],
          trace_id: trace_id
        )
      when "list"
        list_projects(event: event, trace_id: trace_id)
      when "where"
        current_project_context(event: event, trace_id: trace_id)
      else
        Result.new(handled: false)
      end
    end

    def handle_quiz_command(event:, command:, trace_id:)
      case command[:command]
      when "open"
        open_quiz(event: event, use_case_name: command[:use_case_name], trace_id: trace_id)
      when "list"
        list_quizzes(event: event, trace_id: trace_id)
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

    def start_project_setup(event:, project_name:, description:, repository_input:, trace_id:)
      request_id = request_id_for(event, "start-project-setup")
      payload = {
        "guided_alignment" => true
      }
      unless project_name.to_s.empty?
        payload["project_name"] = project_name
        payload["directory_name"] = project_name
      end
      payload["description"] = description unless description.to_s.empty?
      payload["repository_input"] = repository_input unless repository_input.to_s.empty?

      response = client.command(
        name: "StartProjectSetup",
        payload: payload,
        actor_identifier: actor_identifier_for(event),
        request_id: request_id
      )
      body = response.body
      remember_context(chat_id: event.chat_id, body: body)

      Result.new(
        handled: true,
        command: "project_new",
        message: render_setup_response(body: body, trace_id: trace_id, user_text: event.text),
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
        message: render_setup_response(body: body, trace_id: trace_id, user_text: event.text),
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
          message: render_project_setup_status(body: body, trace_id: trace_id),
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

    def open_quiz(event:, use_case_name:, trace_id:)
      project_id = active_project_id(event.chat_id)
      return missing_project_context_result(command: "quiz_open", trace_id: trace_id) unless project_id

      response = client.command(
        name: "OpenQuiz",
        payload: {"project_id" => project_id, "use_case_name" => use_case_name},
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "open-quiz")
      )
      body = response.body
      remember_quiz_context(chat_id: event.chat_id, use_case_name: use_case_name, body: body)

      Result.new(
        handled: true,
        command: "quiz_open",
        message: render_quiz(body: body, trace_id: trace_id),
        api_response: body
      )
    end

    def advance_active_quiz(event:, trace_id:)
      context = active_quiz_context(event.chat_id)
      response = client.command(
        name: "AdvanceQuiz",
        payload: {
          "project_id" => context.fetch("project_id"),
          "use_case_name" => context["use_case_name"],
          "question" => context.fetch("question"),
          "answer" => event.text.to_s,
          "tags" => context.fetch("tags", [])
        },
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "advance-quiz")
      )
      body = response.body
      remember_quiz_context(chat_id: event.chat_id, use_case_name: context["use_case_name"], body: body)

      Result.new(
        handled: true,
        command: "quiz_advance",
        message: render_quiz(body: body, trace_id: trace_id),
        api_response: body
      )
    end

    def list_quizzes(event:, trace_id:)
      project_id = active_project_id(event.chat_id)
      return missing_project_context_result(command: "quiz_list", trace_id: trace_id) unless project_id

      response = client.query(
        name: "ListQuizzes",
        payload: {"project_id" => project_id},
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "list-quizzes")
      )

      Result.new(
        handled: true,
        command: "quiz_list",
        message: render_quiz_list(body: response.body, trace_id: trace_id),
        api_response: response.body
      )
    end

    def render_setup_response(body:, trace_id:, user_text:)
      @prompt_renderer.render(body: body, user_text: user_text, trace_id: trace_id)
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
        *setup_saga_lines(project["setup_saga"]),
        "Trace: #{trace_id}"
      ].join("\n")
    end

    def render_project_setup_status(body:, trace_id:)
      payload = body["data"].is_a?(Hash) ? body["data"] : body
      [
        summary_from(body),
        *setup_saga_lines(payload["setup_saga"]),
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

    def render_quiz(body:, trace_id:)
      data = body["data"] || {}
      if body.fetch("status", "") == "error"
        return [
          "Quiz error: #{summary_from(body)}",
          *error_lines_from(body),
          "Trace: #{trace_id}"
        ].join("\n")
      end

      if %w[done cancelled].include?(data["status"].to_s)
        return [
          data["summary"],
          "Trace: #{trace_id}"
        ].join("\n")
      end

      lines = [
        data["question"],
        "Controls: skip, done, cancel"
      ]
      tags = Array(data["tags"])
      lines << "Tags: #{tags.join(', ')}" if tags.any?
      lines << "Trace: #{trace_id}"
      lines.join("\n")
    end

    def render_quiz_list(body:, trace_id:)
      quizzes = body.dig("data", "quizzes") || []
      lines = quizzes.first(20).map do |quiz|
        scope = quiz["use_case_name"].to_s.empty? ? "project" : quiz["use_case_name"]
        "- #{quiz['id']}: #{scope} (#{quiz['entry_count']} entries)"
      end
      [
        "Quizzes:",
        lines.empty? ? "No quizzes found." : lines.join("\n"),
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

    def remember_quiz_context(chat_id:, use_case_name:, body:)
      data = body["data"] || {}
      project_id = data.dig("quiz", "project_id")
      @project_ids_by_chat[chat_id] = project_id if project_id

      if data["status"].to_s == "collecting" && data["question"].to_s.strip != ""
        @quiz_contexts_by_chat[chat_id] = {
          "project_id" => project_id,
          "use_case_name" => use_case_name,
          "question" => data["question"],
          "tags" => data["tags"] || []
        }
      else
        @quiz_contexts_by_chat.delete(chat_id)
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

    def setup_saga_lines(setup_saga)
      return [] unless setup_saga.is_a?(Hash) && !setup_saga.empty?

      materialization = setup_saga["materialization"].is_a?(Hash) ? setup_saga["materialization"] : {}
      initial = setup_saga["initial_implementation"].is_a?(Hash) ? setup_saga["initial_implementation"] : {}
      ticket_operation = setup_saga["ticket_operation"].is_a?(Hash) ? setup_saga["ticket_operation"] : {}
      validation = materialization["validation"].is_a?(Hash) ? materialization["validation"] : {}
      validation_status = materialization["validation_status"].to_s
      validation_status = validation["status"].to_s if validation_status.empty?
      workspace = materialization["workspace"].is_a?(Hash) ? materialization["workspace"] : {}
      lines = [
        "Setup stage: #{human_label(setup_saga['stage'])}",
        "Setup status: #{human_label(setup_saga['status'])}",
        "Materialization: #{human_label(materialization['status'])}",
        "Initial implementation: #{human_label(initial['status'])}#{initial['runnable'] == true ? ' (runnable)' : ''}",
        "Ticket operation: #{human_label(ticket_operation['status'])}"
      ]
      lines.insert(4, "Validation: #{human_label(validation_status)}") unless validation_status.strip.empty?
      workspace_path = workspace["relative_path"].to_s.strip
      workspace_path = workspace["path"].to_s.strip if workspace_path.empty?
      lines << "Workspace: #{workspace_path}" unless workspace_path.empty?
      lines
    end

    def human_label(value)
      label = value.to_s.tr("_", " ").strip
      label.empty? ? "unknown" : label
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

      return project_new_command(parts) if action == "new"
      return {command: "list"} if raw.match?(%r{\A/project\s+list\s*\z}i)
      return {command: "where"} if raw.match?(%r{\A/project\s+where\s*\z}i)

      nil
    end

    def project_new_command(parts)
      project_name = parts[2].to_s
      return {command: "new", project_name: nil, description: nil, repository_input: nil} if project_name.empty?
      return nil unless valid_project_name?(project_name)

      remainder = parts[3..] || []
      repository_input = nil
      description_parts = []
      remainder.each do |part|
        if repository_input.nil? && repository_input?(part)
          repository_input = part
        else
          description_parts << part
        end
      end

      {
        command: "new",
        project_name: project_name,
        description: description_parts.join(" ").strip,
        repository_input: repository_input
      }
    end

    def shellsplit(raw)
      Shellwords.split(raw)
    rescue ArgumentError
      raw.split(/\s+/)
    end

    def valid_project_name?(value)
      value.to_s.match?(%r{\A[a-zA-Z0-9._\-]+\z})
    end

    def repository_input?(value)
      raw = value.to_s
      raw.match?(%r{\Ahttps?://\S+\z}) ||
        raw.match?(%r{\Agit@\S+:\S+\z}) ||
        raw.match?(%r{\A[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+\z})
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

    def parse_quiz_command(text)
      raw = text.to_s.strip
      return nil unless raw.start_with?("/quiz")
      return {command: "open", use_case_name: nil} if raw.match?(%r{\A/quiz\s*\z}i)
      return {command: "list"} if raw.match?(%r{\A/quiz\s+list\s*\z}i)

      for_match = raw.match(%r{\A/quiz\s+for\s+(.+?)\s*\z}i)
      return {command: "open", use_case_name: for_match[1].strip} if for_match

      nil
    end

    def missing_project_context_result(command:, trace_id:)
      Result.new(
        handled: true,
        command: command,
        message: "No active Rails project for this command.\nTrace: #{trace_id}",
        api_response: nil
      )
    end

    def slash?(text)
      text.to_s.strip.start_with?("/")
    end

    def setup_control_command?(text)
      %w[/skip /done /cancel].include?(text.to_s.strip.downcase)
    end

    def quiz_control_or_answer?(text)
      raw = text.to_s.strip
      return true unless slash?(raw)

      %w[/skip /done /cancel].include?(raw.downcase)
    end

    def active_quiz_context(chat_id)
      @quiz_contexts_by_chat[chat_id]
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
