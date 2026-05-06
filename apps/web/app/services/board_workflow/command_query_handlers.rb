module BoardWorkflow
  class CommandQueryHandlers
    def self.register(dispatcher)
      new.register(dispatcher)
    end

    def initialize(ticket_execution_bridge: nil)
      @ticket_execution_bridge = ticket_execution_bridge
    end

    def register(dispatcher)
      dispatcher.register_command("CreateTicket", method(:create_ticket))
      dispatcher.register_command("UpdateTicket", method(:update_ticket))
      dispatcher.register_command("MoveTicket", method(:move_ticket))
      dispatcher.register_command("AttachDocumentToTicket", method(:attach_document_to_ticket))
      dispatcher.register_command("StartTicketExecution", method(:start_ticket_execution))
      dispatcher.register_query("PickNextTicket", method(:pick_next_ticket))
      dispatcher.register_query("GetBoard", method(:get_board))
      dispatcher.register_query("GetTicketsByProject", method(:get_tickets_by_project))
      dispatcher
    end

    def create_ticket(payload:, context:, request_id:)
      board = find_board(value_from(payload, "board_id"))
      return missing_board_result(request_id: request_id) unless board

      column = target_column_for(board: board, payload: payload, default: true)
      return missing_column_result(request_id: request_id) unless column

      ticket = nil
      Ticket.transaction do
        ticket = board.tickets.create!(ticket_attrs(payload).merge(column: column))
        sync_documents_if_present(ticket: ticket, payload: payload)
      end

      CommandQuery::Result.ok(
        request_id: request_id,
        data: ticket_result_data(ticket.reload, summary: "Ticket created."),
        effects: [
          {
            "type" => "ticket_created",
            "ticket_id" => ticket.id,
            "board_id" => board.id,
            "project_id" => board.project_id
          }
        ]
      )
    rescue ActiveRecord::RecordInvalid => e
      invalid_record_result(e.record, request_id: request_id, summary: "Ticket could not be created.")
    rescue ArgumentError => e
      invalid_payload_result(request_id: request_id, message: e.message)
    end

    def update_ticket(payload:, context:, request_id:)
      ticket = find_ticket(value_from(payload, "ticket_id"))
      return missing_ticket_result(request_id: request_id) unless ticket

      attrs = ticket_attrs(payload).compact
      if attrs.empty? && !key_present?(payload, "document_ids")
        return invalid_payload_result(request_id: request_id, message: "ticket fields or document_ids are required")
      end

      Ticket.transaction do
        ticket.update!(attrs) if attrs.any?
        sync_documents_if_present(ticket: ticket, payload: payload)
      end

      CommandQuery::Result.ok(
        request_id: request_id,
        data: ticket_result_data(ticket.reload, summary: "Ticket updated."),
        effects: [
          {
            "type" => "ticket_updated",
            "ticket_id" => ticket.id,
            "board_id" => ticket.board_id,
            "project_id" => ticket.project_id
          }
        ]
      )
    rescue ActiveRecord::RecordInvalid => e
      invalid_record_result(e.record, request_id: request_id, summary: "Ticket could not be updated.")
    rescue ArgumentError => e
      invalid_payload_result(request_id: request_id, message: e.message)
    end

    def move_ticket(payload:, context:, request_id:)
      ticket = find_ticket(value_from(payload, "ticket_id"))
      return missing_ticket_result(request_id: request_id) unless ticket

      column = target_column_for(board: ticket.board, payload: payload, default: false)
      return missing_column_result(request_id: request_id) unless column

      source_column_id = ticket.column_id
      ticket.transition_to_column!(column)

      CommandQuery::Result.ok(
        request_id: request_id,
        data: ticket_result_data(ticket.reload, summary: "Ticket moved."),
        effects: [
          {
            "type" => "ticket_moved",
            "ticket_id" => ticket.id,
            "from_column_id" => source_column_id,
            "to_column_id" => column.id,
            "project_id" => ticket.project_id
          }
        ]
      )
    rescue ActiveRecord::RecordInvalid => e
      invalid_record_result(e.record, request_id: request_id, summary: "Ticket could not be moved.")
    end

    def attach_document_to_ticket(payload:, context:, request_id:)
      ticket = find_ticket(value_from(payload, "ticket_id"))
      return missing_ticket_result(request_id: request_id) unless ticket
      document = find_document(value_from(payload, "document_id"))
      return missing_document_result(request_id: request_id) unless document

      role = value_from(payload, "role").presence || TicketManagement::DocumentLinkSyncService.role_for(document)
      link = ticket.ticket_document_links.find_or_initialize_by(document: document)
      link.role = role
      link.save!

      CommandQuery::Result.ok(
        request_id: request_id,
        data: ticket_result_data(ticket.reload, summary: "Document attached to ticket.").merge(
          "document_id" => document.id,
          "ticket_document_link_id" => link.id
        ),
        effects: [
          {
            "type" => "document_attached_to_ticket",
            "ticket_id" => ticket.id,
            "document_id" => document.id,
            "role" => link.role,
            "project_id" => ticket.project_id
          }
        ]
      )
    rescue ActiveRecord::RecordInvalid => e
      invalid_record_result(e.record, request_id: request_id, summary: "Document could not be attached to ticket.")
    end

    def start_ticket_execution(payload:, context:, request_id:)
      ticket = find_ticket(value_from(payload, "ticket_id"))
      return missing_ticket_result(request_id: request_id) unless ticket
      return invalid_payload_result(request_id: request_id, message: "archived tickets cannot be started") if ticket.archived_at.present?

      bridge_result = ticket_execution_bridge.start(
        ticket: ticket,
        request_id: request_id,
        actor_identifier: actor_identifier_from(context)
      )
      ticket.record_runtime_execution!(bridge_result)

      if bridge_result.ok?
        return CommandQuery::Result.ok(
          request_id: request_id,
          data: ticket_result_data(ticket.reload, summary: "Ticket execution started."),
          effects: [
            {
              "type" => "ticket_execution_started",
              "ticket_id" => ticket.id,
              "project_id" => ticket.project_id,
              "runtime_execution_id" => bridge_result.execution_id,
              "runtime_workstream_id" => bridge_result.runtime_workstream_id,
              "runtime_task_id" => bridge_result.runtime_task_id
            }
          ]
        )
      end

      CommandQuery::Result.new(
        status: "error",
        request_id: request_id,
        data: ticket_result_data(ticket.reload, summary: "Ticket execution could not be started."),
        effects: [
          {
            "type" => "ticket_execution_failed",
            "ticket_id" => ticket.id,
            "project_id" => ticket.project_id,
            "error_code" => bridge_result.error_code
          }
        ],
        errors: [
          {
            code: bridge_result.error_code,
            message: bridge_result.error_message,
            details: ticket_execution_error_details(ticket: ticket, bridge_result: bridge_result)
          }
        ]
      )
    end

    def pick_next_ticket(payload:, context:, request_id:)
      board = board_from_payload(payload)
      return missing_board_result(request_id: request_id) unless board

      ticket = Ticket.pick_next_for(board: board, assignee: value_from(payload, "assignee"))
      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "summary" => ticket ? "Next ticket selected." : "No active tickets found.",
          "board_id" => board.id,
          "project_id" => board.project_id,
          "ticket_id" => ticket&.id,
          "ticket" => ticket ? ticket_data(ticket) : nil
        },
        effects: []
      )
    end

    def get_board(payload:, context:, request_id:)
      board = board_from_payload(payload)
      return missing_board_result(request_id: request_id) unless board

      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "summary" => "Board retrieved.",
          "board_id" => board.id,
          "project_id" => board.project_id,
          "board" => board_data(board)
        },
        effects: []
      )
    end

    def get_tickets_by_project(payload:, context:, request_id:)
      project = find_project(value_from(payload, "project_id"))
      return missing_project_result(request_id: request_id) unless project

      tickets = Ticket.for_project(project.id).visible_on_board.ordered_for_board.includes(:board, :column, :documents)
      CommandQuery::Result.ok(
        request_id: request_id,
        data: {
          "summary" => "Project tickets retrieved.",
          "project_id" => project.id,
          "tickets" => tickets.map { |ticket| ticket_data(ticket) },
          "count" => tickets.count
        },
        effects: []
      )
    end

    private

    def board_from_payload(payload)
      board = find_board(value_from(payload, "board_id"))
      return board if board

      project_id = value_from(payload, "project_id")
      return nil if project_id.blank?

      Board.for_project(project_id).order(:name).first
    end

    def ticket_result_data(ticket, summary:)
      {
        "summary" => summary,
        "ticket_id" => ticket.id,
        "board_id" => ticket.board_id,
        "project_id" => ticket.project_id,
        "ticket" => ticket_data(ticket)
      }
    end

    def board_data(board)
      {
        "id" => board.id,
        "name" => board.name,
        "project_id" => board.project_id,
        "project_key" => board.project_key,
        "columns" => board.columns.order(:position).map do |column|
          {
            "id" => column.id,
            "key" => column.key,
            "title" => column.title,
            "position" => column.position,
            "tickets" => board.tickets.visible_on_board.where(column_id: column.id).ordered_for_board.map { |ticket| ticket_data(ticket) }
          }
        end
      }
    end

    def ticket_data(ticket)
      {
        "id" => ticket.id,
        "board_id" => ticket.board_id,
        "project_id" => ticket.project_id,
        "column_id" => ticket.column_id,
        "column_key" => ticket.column.key,
        "title" => ticket.title,
        "description" => ticket.description,
        "priority" => ticket.priority,
        "workflow_status" => ticket.workflow_status,
        "kind" => ticket.kind,
        "severity" => ticket.severity,
        "scope" => ticket.scope,
        "source" => ticket.source,
        "resolution" => ticket.resolution,
        "owner" => ticket.owner,
        "branch" => ticket.branch,
        "pr" => ticket.pr,
        "commits" => ticket.commits,
        "ready_at" => ticket.ready_at&.iso8601,
        "started_at" => ticket.started_at&.iso8601,
        "reviewed_at" => ticket.reviewed_at&.iso8601,
        "closed_at" => ticket.closed_at&.iso8601,
        "assignee" => ticket.assignee,
        "archived_at" => ticket.archived_at&.iso8601,
        "runtime_execution" => ticket.runtime_execution,
        "document_links" => ticket.ticket_document_links.includes(:document).map do |link|
          {
            "id" => link.id,
            "document_id" => link.document_id,
            "role" => link.role,
            "artifact_type" => link.document.artifact_type,
            "title" => link.document.title
          }
        end
      }
    end

    def ticket_attrs(payload)
      attrs = {}
      attrs[:title] = value_from(payload, "title").to_s.strip if key_present?(payload, "title")
      attrs[:description] = value_from(payload, "description").to_s if key_present?(payload, "description")
      attrs[:priority] = value_from(payload, "priority").to_s if key_present?(payload, "priority")
      attrs[:kind] = value_from(payload, "kind").to_s if key_present?(payload, "kind")
      attrs[:severity] = value_from(payload, "severity").to_s if key_present?(payload, "severity")
      attrs[:scope] = value_from(payload, "scope").to_s if key_present?(payload, "scope")
      attrs[:source] = value_from(payload, "source").to_s if key_present?(payload, "source")
      attrs[:resolution] = value_from(payload, "resolution").to_s if key_present?(payload, "resolution")
      attrs[:owner] = value_from(payload, "owner").to_s if key_present?(payload, "owner")
      attrs[:branch] = value_from(payload, "branch").to_s if key_present?(payload, "branch")
      attrs[:pr] = value_from(payload, "pr").to_s if key_present?(payload, "pr")
      attrs[:commits] = Array(value_from(payload, "commits")).map(&:to_s) if key_present?(payload, "commits")
      attrs[:assignee] = value_from(payload, "assignee").to_s if key_present?(payload, "assignee")
      attrs[:use_case_id] = value_from(payload, "use_case_id") if key_present?(payload, "use_case_id")
      attrs
    end

    def target_column_for(board:, payload:, default:)
      column_id = value_from(payload, "column_id")
      return board.columns.find_by(id: column_id) if column_id.present?

      column_key = value_from(payload, "column_key")
      return board.columns.find_by(key: column_key) if column_key.present?

      default ? board.columns.order(:position).first : nil
    end

    def sync_documents_if_present(ticket:, payload:)
      return unless key_present?(payload, "document_ids")

      TicketManagement::DocumentLinkSyncService.new(
        ticket: ticket,
        document_ids: value_from(payload, "document_ids")
      ).call
    end

    def invalid_record_result(record, request_id:, summary:)
      CommandQuery::Result.new(
        status: "error",
        request_id: request_id,
        data: {"summary" => summary},
        effects: [],
        errors: record_errors(record)
      )
    end

    def invalid_payload_result(request_id:, message:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "invalid_payload",
        message: message
      )
    end

    def missing_project_result(request_id:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "project_not_found",
        message: "project was not found"
      )
    end

    def missing_board_result(request_id:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "board_not_found",
        message: "board was not found"
      )
    end

    def missing_column_result(request_id:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "column_not_found",
        message: "column was not found on the board"
      )
    end

    def missing_ticket_result(request_id:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "ticket_not_found",
        message: "ticket was not found"
      )
    end

    def missing_document_result(request_id:)
      CommandQuery::Result.error(
        request_id: request_id,
        code: "document_not_found",
        message: "document was not found"
      )
    end

    def record_errors(record)
      record.errors.map do |error|
        {
          code: "invalid_#{error.attribute}",
          message: "#{error.attribute} #{error.message}",
          details: {"attribute" => error.attribute.to_s}
        }
      end
    end

    def find_project(project_id)
      return nil if project_id.blank?

      Project.find_by(id: project_id)
    end

    def find_board(board_id)
      return nil if board_id.blank?

      Board.find_by(id: board_id)
    end

    def find_ticket(ticket_id)
      return nil if ticket_id.blank?

      Ticket.find_by(id: ticket_id)
    end

    def find_document(document_id)
      return nil if document_id.blank?

      Document.find_by(id: document_id)
    end

    def key_present?(hash, key)
      source = hash_from(hash)
      source.key?(key.to_s) || source.key?(key.to_sym)
    end

    def value_from(hash, *keys)
      source = hash_from(hash)
      keys.each do |key|
        return source[key.to_s] if source.key?(key.to_s)
        return source[key.to_sym] if source.key?(key.to_sym)
      end
      nil
    end

    def hash_from(value)
      value.is_a?(Hash) ? value : {}
    end

    def ticket_execution_bridge
      @ticket_execution_bridge ||= RuntimeBridge::TicketExecutionBridge.new
    end

    def ticket_execution_error_details(ticket:, bridge_result:)
      details = {"ticket_id" => ticket.id}
      return details unless bridge_result.respond_to?(:error_details) && bridge_result.error_details.is_a?(Hash)

      details.merge(bridge_result.error_details)
    end

    def actor_identifier_from(context)
      value_from(context, "actor_identifier", "actor_id").to_s
    end
  end
end
