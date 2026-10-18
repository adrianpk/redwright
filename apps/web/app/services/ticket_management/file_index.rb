module TicketManagement
  class FileIndex
    PATTERNS = %w[ops/*/ticket/**/artifact.md].freeze
    SOURCE_FIELDS = %w[title priority assignee pull_request_url started_at paused_at sent_to_review_at
      review_started_at review_completed_at merge_started_at merged_at archived_at runtime_execution_id
      runtime_execution_status runtime_project_ref runtime_workstream_id runtime_task_id runtime_state
      runtime_execution_started_at runtime_execution_error kind severity scope source resolution owner
      branch pr commits ready_at reviewed_at closed_at ticket_key specification_path tracker_path
      specification_revision created_at updated_at].freeze

    def initialize(project)
      @project = project
      @store = Specifications::FileStore.new(project)
    end

    def write(ticket)
      previous = ticket.relative_path.present? ? @store.read(ticket.relative_path) : nil
      fields = ticket.attributes.slice(*SOURCE_FIELDS).transform_values { |value| value.respond_to?(:iso8601) ? value.iso8601(6) : value }
      metadata = (previous&.dig(:metadata) || {}).merge(fields)
      metadata.merge!("title" => ticket.title, "artifact_type" => "ticket", "status" => ticket.workflow_status,
        "board_key" => ticket.board.project_key, "column_key" => ticket.column.key,
        "case_slug" => ticket.use_case&.slug.to_s, "description_nil" => ticket.description.nil?,
        "project_id" => metadata["project_id"].presence || @project.id.to_s)
      @store.write(path: ticket.relative_path, metadata: metadata, body: ticket.description.to_s,
        revision: ticket.revision.presence || ticket.source_hash)
    end

    def reconcile!
      entries = @store.entries(patterns: PATTERNS)
      values = entries.map { |entry| values_for(entry) }
      keys = values.map { |value| value.fetch(:ticket_key) }
      raise Specifications::Error, "Duplicate ticket keys in project files." unless keys.uniq.size == keys.size
      Ticket.transaction do
        values.each do |attributes|
          ticket = Ticket.for_project(@project.id).find_by(ticket_key: attributes.fetch(:ticket_key))
          if ticket
            ticket.update_columns(attributes)
          else
            Ticket.insert_all!([attributes])
          end
        end
        missing = Ticket.for_project(@project.id).where.not(relative_path: entries.map { |entry| entry[:path] })
        # Missing source files never authorize deleting execution history or comments.
        raise Specifications::Error, "A ticket file is missing. Restore it before continuing." if missing.exists?
      end
    end

    def values_for(entry)
      metadata = entry.fetch(:metadata)
      board = @project.boards.find_by(project_key: metadata["board_key"])
      column = board&.columns&.find_by(key: metadata["column_key"])
      use_case = @project.use_cases.find_by(slug: metadata["case_slug"]) if metadata["case_slug"].present?
      key = metadata["ticket_key"]
      unless board && column && Ticket::TICKET_KEY_PATTERN.match?(key.to_s) && Ticket::WORKFLOW_STATUSES.include?(metadata["status"])
        raise Specifications::Error, "Invalid ticket identity, board, column, or status in #{entry[:path]}."
      end
      if metadata["case_slug"].present? && !use_case
        raise Specifications::Error, "Unknown feature in #{entry[:path]}."
      end
      if Ticket.workflow_status_for_column_key(column.key) != metadata["status"]
        raise Specifications::Error, "Ticket status and column disagree in #{entry[:path]}."
      end
      metadata.slice(*SOURCE_FIELDS).symbolize_keys.merge(board_id: board.id, column_id: column.id,
        use_case_id: use_case&.id, workflow_status: metadata["status"], relative_path: entry[:path],
        source_hash: entry[:source_hash], source_modified_at: entry[:source_modified_at],
        created_at: metadata["created_at"] || Time.current, updated_at: metadata["updated_at"] || entry[:source_modified_at])
    end
  end
end
