# frozen_string_literal: true

require "shellwords"

require_relative "project_setup_prompt_renderer"
require_relative "telegram_ticket_command_adapter"

module Redwright
  class TelegramProjectSetupAdapter
    Result = Struct.new(:handled, :command, :message, :messages, :api_response, keyword_init: true) do
      def handled?
        handled == true
      end

      def message_list
        Array(messages || message).compact
      end
    end

    TERMINAL_STATES = %w[completed cancelled failed needs_reconciliation].freeze

    def initialize(client:, prompt_renderer: ProjectSetupPromptRenderer.new, telegram_client: nil, async_ticket_execution: nil, thread_factory: nil, out: nil)
      @client = client
      @prompt_renderer = prompt_renderer
      @session_ids_by_chat = {}
      @project_ids_by_chat = {}
      @quiz_contexts_by_chat = {}
      @dump_contexts_by_chat = {}
      @ticket_command_adapter = TelegramTicketCommandAdapter.new(
        client: client,
        project_ids_by_chat: @project_ids_by_chat,
        telegram_client: telegram_client,
        async_ticket_execution: async_ticket_execution,
        thread_factory: thread_factory,
        out: out
      )
    end

    def handles_event?(event)
      return true if active_session_id(event.chat_id) && setup_control_command?(event.text)
      return true if active_quiz_context(event.chat_id) && quiz_control_or_answer?(event.text)
      return true if active_dump_context(event.chat_id) && dump_control_or_message?(event.text)

      return true if parse_command(event.text)
      return true if ticket_command_adapter.handles_event?(event)
      return true if parse_quiz_command(event.text)
      return true if parse_dump_command(event.text)
      return true if active_session_id(event.chat_id) && !slash?(event.text)

      false
    end

    def handle(event, trace_id:)
      return advance_active_session(event: event, trace_id: trace_id) if active_session_id(event.chat_id) && setup_control_command?(event.text)
      return advance_active_quiz(event: event, trace_id: trace_id) if active_quiz_context(event.chat_id) && quiz_control_or_answer?(event.text)
      return handle_active_dump(event: event, trace_id: trace_id) if active_dump_context(event.chat_id) && dump_control_or_message?(event.text)

      command = parse_command(event.text)
      return handle_project_command(event: event, command: command, trace_id: trace_id) if command
      return ticket_command_adapter.handle(event, trace_id: trace_id) if ticket_command_adapter.handles_event?(event)
      quiz_command = parse_quiz_command(event.text)
      return handle_quiz_command(event: event, command: quiz_command, trace_id: trace_id) if quiz_command
      dump_command = parse_dump_command(event.text)
      return handle_dump_command(event: event, command: dump_command, trace_id: trace_id) if dump_command
      return advance_active_session(event: event, trace_id: trace_id) if active_session_id(event.chat_id) && !slash?(event.text)

      Result.new(handled: false)
    end

    private

    attr_reader :client
    attr_reader :ticket_command_adapter

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

    def handle_dump_command(event:, command:, trace_id:)
      case command[:command]
      when "open"
        open_dump(event: event, use_case_name: command[:use_case_name], trace_id: trace_id)
      when "list"
        list_dumps(event: event, trace_id: trace_id)
      when "show"
        show_dump(event: event, identifier: command[:identifier], trace_id: trace_id)
      when "done"
        finish_active_dump(event: event, trace_id: trace_id)
      when "cancel"
        cancel_active_dump(event: event, trace_id: trace_id)
      when "curate"
        curate_active_dump(event: event, trace_id: trace_id)
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
          "answer" => event.text.to_s
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

    def open_dump(event:, use_case_name:, trace_id:)
      project_id = active_project_id(event.chat_id)
      return missing_project_context_result(command: "dump_open", trace_id: trace_id) unless project_id

      response = client.command(
        name: "OpenDump",
        payload: {"project_id" => project_id, "use_case_name" => use_case_name},
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "open-dump")
      )
      body = response.body
      remember_dump_context(chat_id: event.chat_id, use_case_name: use_case_name, body: body)

      Result.new(
        handled: true,
        command: "dump_open",
        message: render_dump(body: body, trace_id: trace_id),
        api_response: body
      )
    end

    def handle_active_dump(event:, trace_id:)
      command = parse_dump_command(event.text)
      return handle_dump_command(event: event, command: command, trace_id: trace_id) if command

      append_active_dump(event: event, trace_id: trace_id)
    end

    def append_active_dump(event:, trace_id:)
      context = active_dump_context(event.chat_id)
      response = client.command(
        name: "AppendDump",
        payload: {
          "project_id" => context.fetch("project_id"),
          "dump_id" => context.fetch("dump_id"),
          "raw_input" => event.text.to_s
        },
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "append-dump")
      )
      body = response.body
      remember_dump_context(chat_id: event.chat_id, use_case_name: context["use_case_name"], body: body)

      Result.new(
        handled: true,
        command: "dump_append",
        message: render_dump(body: body, trace_id: trace_id),
        api_response: body
      )
    end

    def finish_active_dump(event:, trace_id:)
      context = active_dump_context(event.chat_id)
      return missing_dump_context_result(command: "dump_done", trace_id: trace_id) unless context

      response = client.command(
        name: "DoneDump",
        payload: {"project_id" => context.fetch("project_id"), "dump_id" => context.fetch("dump_id")},
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "done-dump")
      )
      body = response.body
      remember_dump_context(chat_id: event.chat_id, use_case_name: context["use_case_name"], body: body)

      Result.new(
        handled: true,
        command: "dump_done",
        message: render_dump(body: body, trace_id: trace_id),
        api_response: body
      )
    end

    def cancel_active_dump(event:, trace_id:)
      context = active_dump_context(event.chat_id)
      return missing_dump_context_result(command: "dump_cancel", trace_id: trace_id) unless context

      response = client.command(
        name: "CancelDump",
        payload: {"project_id" => context.fetch("project_id"), "dump_id" => context.fetch("dump_id")},
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "cancel-dump")
      )
      body = response.body
      remember_dump_context(chat_id: event.chat_id, use_case_name: context["use_case_name"], body: body)

      Result.new(
        handled: true,
        command: "dump_cancel",
        message: render_dump(body: body, trace_id: trace_id),
        api_response: body
      )
    end

    def curate_active_dump(event:, trace_id:)
      context = active_dump_context(event.chat_id)
      return missing_dump_context_result(command: "dump_curate", trace_id: trace_id) unless context

      response = client.command(
        name: "CurateDump",
        payload: {"project_id" => context.fetch("project_id"), "dump_id" => context.fetch("dump_id")},
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "curate-dump")
      )
      body = response.body
      remember_dump_context(chat_id: event.chat_id, use_case_name: context["use_case_name"], body: body)

      Result.new(
        handled: true,
        command: "dump_curate",
        message: render_dump(body: body, trace_id: trace_id),
        api_response: body
      )
    end

    def list_dumps(event:, trace_id:)
      project_id = active_project_id(event.chat_id)
      return missing_project_context_result(command: "dump_list", trace_id: trace_id) unless project_id

      response = client.query(
        name: "ListDumps",
        payload: {"project_id" => project_id},
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "list-dumps")
      )

      Result.new(
        handled: true,
        command: "dump_list",
        message: render_dump_list(body: response.body, trace_id: trace_id),
        api_response: response.body
      )
    end

    def show_dump(event:, identifier:, trace_id:)
      project_id = active_project_id(event.chat_id)
      return missing_project_context_result(command: "dump_show", trace_id: trace_id) unless project_id

      response = client.query(
        name: "ShowDump",
        payload: {"project_id" => project_id, "identifier" => identifier},
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "show-dump")
      )

      Result.new(
        handled: true,
        command: "dump_show",
        message: render_dump(body: response.body, trace_id: trace_id),
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

    def render_dump(body:, trace_id:)
      data = body["data"] || {}
      if body.fetch("status", "") == "error"
        return [
          "Dump error: #{summary_from(body)}",
          *error_lines_from(body),
          "Trace: #{trace_id}"
        ].join("\n")
      end

      dump = data["dump"] || {}
      status = data["status"].to_s
      scope = dump["use_case_name"].to_s.empty? ? "project" : dump["use_case_name"]
      entry_count = dump["entry_count"].to_i
      case status
      when "capturing"
        [
          data["summary"],
          "Dump: #{dump['title']} (#{scope}, #{entry_count} entries)",
          "Controls: /dump done, /dump cancel",
          "Trace: #{trace_id}"
        ].join("\n")
      when "done", "cancelled", "curated"
        [
          data["summary"],
          "Dump: #{dump['title']} (#{entry_count} entries, #{dump['curation_status']})",
          "Trace: #{trace_id}"
        ].join("\n")
      when "shown"
        [
          "Dump: #{dump['title']}",
          "Status: #{dump['status']} / #{dump['capture_status']} / #{dump['curation_status']}",
          "Entries: #{entry_count}",
          "Summary: #{dump['summary'].to_s.strip.empty? ? 'none' : dump['summary']}",
          "Trace: #{trace_id}"
        ].join("\n")
      else
        [
          data["summary"],
          "Trace: #{trace_id}"
        ].join("\n")
      end
    end

    def render_dump_list(body:, trace_id:)
      dumps = body.dig("data", "dumps") || []
      lines = dumps.first(20).map do |dump|
        scope = dump["use_case_name"].to_s.empty? ? "project" : dump["use_case_name"]
        "- #{dump['slug']}: #{scope} (#{dump['entry_count']} entries, #{dump['capture_status']})"
      end
      [
        "Dumps:",
        lines.empty? ? "No dumps found." : lines.join("\n"),
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

    def remember_quiz_context(chat_id:, use_case_name:, body:)
      data = body["data"] || {}
      project_id = data.dig("quiz", "project_id")
      @project_ids_by_chat[chat_id] = project_id if project_id

      if data["status"].to_s == "collecting" && data["question"].to_s.strip != ""
        @quiz_contexts_by_chat[chat_id] = {
          "project_id" => project_id,
          "use_case_name" => use_case_name
        }
      else
        @quiz_contexts_by_chat.delete(chat_id)
      end
    end

    def remember_dump_context(chat_id:, use_case_name:, body:)
      data = body["data"] || {}
      dump = data["dump"] || {}
      project_id = dump["project_id"]
      @project_ids_by_chat[chat_id] = project_id if project_id

      if data["status"].to_s == "capturing" && dump["capture_status"].to_s == "capturing"
        @dump_contexts_by_chat[chat_id] = {
          "project_id" => project_id,
          "dump_id" => dump.fetch("id"),
          "use_case_name" => use_case_name
        }
      else
        @dump_contexts_by_chat.delete(chat_id)
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

    def parse_quiz_command(text)
      raw = text.to_s.strip
      return nil unless raw.start_with?("/quiz")
      return {command: "open", use_case_name: nil} if raw.match?(%r{\A/quiz\s*\z}i)
      return {command: "list"} if raw.match?(%r{\A/quiz\s+list\s*\z}i)

      for_match = raw.match(%r{\A/quiz\s+for\s+(.+?)\s*\z}i)
      return {command: "open", use_case_name: for_match[1].strip} if for_match

      nil
    end

    def parse_dump_command(text)
      raw = text.to_s.strip
      return nil unless raw.start_with?("/dump")
      return {command: "open", use_case_name: nil} if raw.match?(%r{\A/dump\s*\z}i)
      return {command: "list"} if raw.match?(%r{\A/dump\s+list\s*\z}i)
      return {command: "done"} if raw.match?(%r{\A/dump\s+done\s*\z}i)
      return {command: "cancel"} if raw.match?(%r{\A/dump\s+cancel\s*\z}i)
      return {command: "curate"} if raw.match?(%r{\A/dump\s+curate\s*\z}i)

      show_match = raw.match(%r{\A/dump\s+show\s+([a-zA-Z0-9._\-]+)\s*\z}i)
      return {command: "show", identifier: show_match[1]} if show_match

      for_match = raw.match(%r{\A/dump\s+for\s+(.+?)\s*\z}i)
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

    def missing_dump_context_result(command:, trace_id:)
      Result.new(
        handled: true,
        command: command,
        message: "No active dump for this command.\nTrace: #{trace_id}",
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

    def dump_control_or_message?(text)
      raw = text.to_s.strip
      return true unless slash?(raw)

      !parse_dump_command(raw).nil?
    end

    def active_dump_context(chat_id)
      @dump_contexts_by_chat[chat_id]
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
