module BoardWorkflow
  class CommandQueryHandlers
    include CommandQuery::PayloadReader

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
      dispatcher.register_command("AddTicketComment", method(:add_ticket_comment))
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
      ticket = board.tickets.create!(ticket_attrs(payload).merge(column: column))

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
      return invalid_payload_result(request_id: request_id, message: "ticket fields are required") if attrs.empty?

      ticket.update!(attrs)

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

    def add_ticket_comment(payload:, context:, request_id:)
      ticket = find_ticket(value_from(payload, "ticket_id"))
      return missing_ticket_result(request_id: request_id) unless ticket

      body = value_from(payload, "body").to_s
      return invalid_payload_result(request_id: request_id, message: "body is required") if body.strip.blank?

      comment = ticket.ticket_comments.create!(ticket_comment_attrs(payload: payload, context: context, body: body))

      CommandQuery::Result.ok(
        request_id: request_id,
        data: ticket_result_data(ticket.reload, summary: "Ticket comment added.").merge(
          "comment" => ticket_comment_data(comment.reload)
        ),
        effects: [
          {
            "type" => "ticket_comment_added",
            "ticket_id" => ticket.id,
            "comment_id" => comment.id,
            "project_id" => ticket.project_id,
            "mentions_count" => comment.mentions.count
          }
        ]
      )
    rescue ActiveRecord::RecordInvalid => e
      invalid_record_result(e.record, request_id: request_id, summary: "Ticket comment could not be added.")
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
          "ticket_ref" => ticket&.display_key,
          "ticket_key" => ticket&.ticket_key,
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

      Ticket.reconcile!(project)
      tickets = Ticket.for_project(project.id).visible_on_board.ordered_for_board.includes(:board, :column)
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
        "ticket_ref" => ticket.display_key,
        "ticket_key" => ticket.ticket_key,
        "board_id" => ticket.board_id,
        "project_id" => ticket.project_id,
        "ticket" => ticket_data(ticket)
      }
    end

    def board_data(board)
      Ticket.reconcile!(board.project)
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
        "ticket_key" => ticket.ticket_key,
        "display_key" => ticket.display_key,
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
        "use_case_id" => ticket.use_case_id,
        "use_case_name" => ticket.use_case&.name,
        "archived_at" => ticket.archived_at&.iso8601,
        "runtime_execution" => ticket.runtime_execution,
        "comments" => ticket.ticket_comments.chronological.includes(:mentions).map { |comment| ticket_comment_data(comment) }
      }
    end

    def ticket_comment_data(comment)
      {
        "id" => comment.id,
        "ticket_id" => comment.ticket_id,
        "author_type" => comment.author_type,
        "author_id" => comment.author_id,
        "author_label" => comment.author_label,
        "author_handle" => comment.author_handle,
        "body" => comment.body,
        "created_at" => comment.created_at&.iso8601,
        "mentions" => comment.mentions.map do |mention|
          {
            "id" => mention.id,
            "target_type" => mention.target_type,
            "target_id" => mention.target_id,
            "handle" => mention.handle,
            "display_label" => mention.display_label
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
      attrs[:revision] = value_from(payload, "revision") if key_present?(payload, "revision")
      attrs
    end

    def ticket_comment_attrs(payload:, context:, body:)
      author_label = value_from(payload, "author_label").presence || actor_identifier_from(context).presence || "Unknown actor"
      author_type = value_from(payload, "author_type").presence || (value_from(payload, "author_id").present? ? "user" : "agent")

      {
        body: body,
        author_type: author_type,
        author_id: value_from(payload, "author_id"),
        author_label: author_label,
        author_handle: value_from(payload, "author_handle").presence || author_label.to_s.split("@").first
      }
    end

    def target_column_for(board:, payload:, default:)
      column_id = value_from(payload, "column_id")
      return board.columns.find_by(id: column_id) if column_id.present?

      column_key = value_from(payload, "column_key")
      return board.columns.find_by(key: column_key) if column_key.present?

      default ? board.columns.order(:position).first : nil
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

      board = Board.find_by(id: board_id)
      Ticket.reconcile!(board.project) if board
      board
    end

    def find_ticket(ticket_ref)
      return nil if ticket_ref.blank?

      Ticket.resolve_ref(ticket_ref)
    end

    def find_document(document_id)
      return nil if document_id.blank?

      Document.find_by(id: document_id)
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
