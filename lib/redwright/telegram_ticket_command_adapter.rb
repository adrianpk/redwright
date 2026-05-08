# frozen_string_literal: true

require_relative "trace"

module Redwright
  class TelegramTicketCommandAdapter
    Result = Struct.new(:handled, :command, :message, :messages, :api_response, keyword_init: true) do
      def handled?
        handled == true
      end

      def message_list
        Array(messages || message).compact
      end
    end

    def initialize(client:, project_ids_by_chat:, telegram_client: nil, async_ticket_execution: nil, thread_factory: nil, out: nil)
      @client = client
      @project_ids_by_chat = project_ids_by_chat
      @ticket_ids_by_chat = {}
      @telegram_client = telegram_client
      @async_ticket_execution = async_ticket_execution.nil? ? !telegram_client.nil? : async_ticket_execution
      @thread_factory = thread_factory || ->(&block) { Thread.new(&block) }
      @out = out
    end

    def handles_event?(event)
      !!parse_command(event.text)
    end

    def handle(event, trace_id:)
      command = parse_command(event.text)
      return Result.new(handled: false) unless command

      case command[:command]
      when "list"
        list_tickets(event: event, trace_id: trace_id)
      when "pick"
        pick_ticket(event: event, trace_id: trace_id)
      when "start"
        start_ticket_execution(event: event, ticket_ref: command[:ticket_ref], trace_id: trace_id)
      else
        Result.new(handled: false)
      end
    end

    private

    attr_reader :client, :telegram_client, :thread_factory

    def async_ticket_execution?
      @async_ticket_execution == true
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
      ticket_ref = body["ticket_ref"] || body["ticket_id"] || body.dig("data", "ticket_ref") || body.dig("data", "ticket_id")
      @ticket_ids_by_chat[event.chat_id] = ticket_ref if ticket_ref

      Result.new(
        handled: true,
        command: "ticket_pick",
        message: render_ticket_pick(body: body, trace_id: trace_id),
        api_response: body
      )
    end

    def start_ticket_execution(event:, ticket_ref:, trace_id:)
      if async_ticket_execution?
        return start_ticket_execution_async(event: event, ticket_ref: ticket_ref, trace_id: trace_id)
      end

      response = client.command(
        name: "ExecuteAgentTicket",
        payload: {"ticket_ref" => ticket_ref},
        actor_identifier: actor_identifier_for(event),
        request_id: request_id_for(event, "execute-agent-ticket")
      )
      body = response.body
      remember_ticket_context(chat_id: event.chat_id, body: body)
      messages = render_agent_ticket_execution_messages(body: body, trace_id: trace_id)

      Result.new(
        handled: true,
        command: "ticket_start",
        message: messages.last,
        messages: messages,
        api_response: body
      )
    end

    def start_ticket_execution_async(event:, ticket_ref:, trace_id:)
      request_id = request_id_for(event, "execute-agent-ticket")
      actor_identifier = actor_identifier_for(event)
      ack_message = render_agent_ticket_execution_ack(
        ticket_ref: ticket_ref,
        trace_id: trace_id,
        request_id: request_id
      )

      thread_factory.call do
        run_ticket_execution_async(
          chat_id: event.chat_id,
          ticket_ref: ticket_ref,
          trace_id: trace_id,
          request_id: request_id,
          actor_identifier: actor_identifier
        )
      end

      Result.new(
        handled: true,
        command: "ticket_start",
        message: ack_message,
        messages: [ack_message],
        api_response: {
          "status" => "ok",
          "summary" => "Agent ticket execution accepted.",
          "data" => {
            "execution" => {
              "state" => "accepted",
              "mode" => "targeted",
              "ticket_ref" => ticket_ref,
              "acknowledgement" => {
                "status" => "accepted",
                "message" => "Agent ticket execution accepted.",
                "ticket_ref" => ticket_ref,
                "mode" => "targeted",
                "request_id" => request_id
              }
            }
          }
        }
      )
    end

    def run_ticket_execution_async(chat_id:, ticket_ref:, trace_id:, request_id:, actor_identifier:)
      Trace.with_trace_id(trace_id) do
        response = client.command(
          name: "ExecuteAgentTicket",
          payload: {"ticket_ref" => ticket_ref},
          actor_identifier: actor_identifier,
          request_id: request_id
        )
        body = response.body
        remember_ticket_context(chat_id: chat_id, body: body)
        messages = render_agent_ticket_execution_messages(body: body, trace_id: trace_id)
        final_messages = messages.length > 1 ? messages.drop(1) : messages
        final_messages.each do |message|
          telegram_client.send_message(chat_id: chat_id, text: message.to_s)
        end
      end
    rescue StandardError => e
      telegram_client&.send_message(
        chat_id: chat_id,
        text: [
          "Agent ticket execution failed.",
          "Ticket: #{ticket_ref}",
          "Error: #{e.class}: #{e.message}",
          "Trace: #{trace_id}"
        ].join("\n")
      )
      @out&.puts("telegram ticket_execution_async_error chat=#{chat_id}: #{e.class}: #{e.message}")
    end

    def render_ticket_list(body:, trace_id:)
      tickets = body.dig("data", "tickets") || []
      lines = tickets.first(20).map do |ticket|
        "- #{ticket_ref_for(ticket)}: #{ticket['title']} [#{ticket['column_key']}]"
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
        "Next ticket: #{ticket['title']} (#{ticket_ref_for(ticket)})",
        "Column: #{ticket['column_key']}",
        "Trace: #{trace_id}"
      ].join("\n")
    end

    def render_agent_ticket_execution_messages(body:, trace_id:)
      if body.fetch("status", "") == "error"
        return [
          [
            "Agent ticket execution error: #{summary_from(body)}",
            *error_lines_from(body),
            "Trace: #{trace_id}"
          ].join("\n")
        ]
      end

      execution = body.dig("data", "execution") || {}
      acknowledgement = execution["acknowledgement"] || {}
      terminal = execution["terminal_outcome"]
      ticket_ref = execution["ticket_ref"] || acknowledgement["ticket_ref"] || execution["ticket_key"] || acknowledgement["ticket_key"]
      ticket_id = execution["ticket_id"] || acknowledgement["ticket_id"]
      ack = [
        acknowledgement["message"].to_s.empty? ? "Agent ticket execution accepted." : acknowledgement["message"],
        "Ticket: #{ticket_ref || ticket_id || 'pending'}",
        "Mode: #{execution['mode'] || acknowledgement['mode'] || 'targeted'}",
        "Trace: #{trace_id}"
      ].join("\n")
      return [ack] unless terminal.is_a?(Hash) && !terminal.empty?

      outcome = terminal["status"] || execution["state"] || "unknown"
      heading = %w[blocked failed error].include?(outcome.to_s) ? "Agent ticket execution blocked." : "Agent ticket execution finished."
      final = [
        heading,
        "Ticket: #{terminal['ticket_ref'] || terminal['ticket_key'] || terminal['ticket_id'] || ticket_ref || ticket_id || 'pending'}",
        "Outcome: #{outcome}",
        "Trace: #{trace_id}"
      ].join("\n")
      [ack, final]
    end

    def render_agent_ticket_execution_ack(ticket_ref:, trace_id:, request_id:)
      [
        "Agent ticket execution accepted.",
        "Ticket: #{ticket_ref}",
        "Mode: targeted",
        "Request: #{request_id}",
        "Trace: #{trace_id}"
      ].join("\n")
    end

    def remember_ticket_context(chat_id:, body:)
      project_id = body["project_id"] || body.dig("data", "project_id") || body.dig("data", "execution", "project_id")
      ticket_ref = body["ticket_ref"] || body["ticket_id"] || body.dig("data", "ticket_ref") || body.dig("data", "ticket_id") || body.dig("data", "execution", "ticket_ref") || body.dig("data", "execution", "ticket_id")
      @project_ids_by_chat[chat_id] = project_id if project_id
      @ticket_ids_by_chat[chat_id] = ticket_ref if ticket_ref
    end

    def ticket_ref_for(ticket)
      ticket["display_key"] || ticket["ticket_key"] || ticket["ticket_ref"] || ticket["id"] || "pending"
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

    def active_project_id(chat_id)
      @project_ids_by_chat[chat_id]
    end

    def parse_command(text)
      raw = text.to_s.strip
      return nil unless raw.start_with?("/ticket")
      return {command: "list"} if raw.match?(%r{\A/ticket\s+list\s*\z}i)
      return {command: "pick"} if raw.match?(%r{\A/ticket\s+pick\s*\z}i)

      start_match = raw.match(%r{\A/ticket\s+start\s+([a-zA-Z0-9._\-]+)\s*\z}i)
      return {command: "start", ticket_ref: start_match[1]} if start_match

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
