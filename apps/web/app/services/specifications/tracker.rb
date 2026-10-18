module Specifications
  class Tracker
    def initialize(project:)
      @project = project
      @store = FileStore.new(project)
    end

    def generate!(specification:, tickets: nil, definitions: nil, expected_revision: nil)
      raise Error, "A tracker belongs to one feature." unless specification.use_case
      workflow = Features::Workflow.new(specification.use_case)
      workflow.with_lock do
        workflow.ensure_mutable!
        Document.reconcile!(@project)
        specification.reload
        if expected_revision && expected_revision != specification.source_hash
          raise Error.new("The specification changed during slicing. Review it before trying again.", code: :conflict)
        end
        build!(specification, tickets, definitions, workflow)
      end
    end

    def build!(specification, tickets, definitions, workflow)
      raise Error, "Approve the specification before organizing implementation." unless specification.status.in?(%w[approved accepted final])
      workflow.invalidate_tracker!
      path = specification.relative_path.sub("/spec/", "/tracker/")
      raise Error, "Tracker generation requires a canonical specification path." if path == specification.relative_path
      tickets = definitions ? materialize!(specification, definitions, path) : tickets.to_a
      raise Error, "A tracker needs at least one implementation ticket." if tickets.empty?
      unless specification.project_id == @project.id && tickets.all? { |ticket| ticket.project_id == @project.id }
        raise Error, "Tracker references must belong to the same project."
      end
      if tickets.any? { |ticket| ticket.use_case_id && ticket.use_case_id != specification.use_case_id }
        raise Error, "A ticket cannot move between features during slicing."
      end
      previous = workflow.tracker_entry
      old_keys = Array(previous&.dig(:metadata, "ticket_keys"))
      tickets.each do |ticket|
        ticket.update!(use_case: specification.use_case, specification_path: specification.relative_path,
          specification_revision: specification.source_hash, tracker_path: path)
      end
      Ticket.for_project(@project.id).where(ticket_key: old_keys - tickets.map(&:ticket_key)).each do |ticket|
        column = ticket.board.columns.find_or_create_by!(key: "closed") { |value| value.title = "Closed"; value.position = ticket.board.columns.maximum(:position).to_i + 1 }
        ticket.update!(column: column, resolution: "obsolete")
      end
      revision = @store.read(path)[:source_hash] if @store.root.join(path).file?
      entry = @store.write(path: path, revision: revision, metadata: {
        "title" => "#{specification.title} execution", "artifact_type" => "plan_tracker", "status" => "tracking",
        "project_id" => @project.id.to_s, "case_slug" => specification.use_case&.slug.to_s,
        "specification_path" => specification.relative_path, "specification_revision" => specification.source_hash,
        "ticket_keys" => tickets.map(&:ticket_key), "created_at" => previous&.dig(:metadata, "created_at") || Time.current.iso8601
      }, body: "# #{specification.title} execution\n\n## Tickets\n\n" + tickets.map { |ticket| "- #{ticket.ticket_key}: #{ticket.title}" }.join("\n"))
      Document.reconcile!(@project)
      entry
    end

    def pending_tickets
      tracker_entries.select { |entry| current?(entry) }.flat_map { |entry| pending_for(entry) }.uniq(&:id)
    end

    def pick(scope)
      return scope.ordered_for_board.first unless @store.root.directory?
      entries = tracker_entries
      return scope.where(specification_path: [nil, ""]).ordered_for_board.first if entries.empty?
      first_pending = entries.select { |entry| current?(entry) }.filter_map { |entry| pending_for(entry).first }
      ids = first_pending.map(&:id)
      eligible = scope.where(id: ids).pluck(:id)
      selected = first_pending.find { |ticket| eligible.include?(ticket.id) }
      return selected if selected
      tracked_keys = entries.flat_map { |entry| Array(entry[:metadata]["ticket_keys"]) }
      scope.where(specification_path: [nil, ""]).where.not(ticket_key: tracked_keys).ordered_for_board.first
    end

    private

    def materialize!(specification, definitions, path)
      unless definitions.is_a?(Array) && definitions.size.between?(1, 20) && definitions.all? { |row| row.is_a?(Hash) && row["title"].is_a?(String) && row["title"].present? && row["body"].is_a?(String) }
        raise Error, "Slicing must return between one and twenty complete ticket definitions."
      end
      keys = definitions.filter_map { |row| row["key"].presence }
      existing = specification.use_case.tickets.where(ticket_key: keys).index_by(&:ticket_key)
      raise Error, "Slicing references an unknown or repeated ticket." unless keys.uniq == keys && existing.keys.sort == keys.sort
      board = @project.boards.order(:id).first
      column = board&.columns&.find_by(key: "backlog") || board&.columns&.order(:position)&.first
      raise Error, "Set up a board before slicing this feature." unless column
      definitions.map do |row|
        ticket = row["key"].present? ? existing.fetch(row["key"]) : board.tickets.new(column: column, use_case: specification.use_case)
        ticket.assign_attributes(title: row["title"], description: row["body"],
          specification_path: specification.relative_path, specification_revision: specification.source_hash, tracker_path: path)
        ticket.assign_attributes(column: column, resolution: nil, closed_at: nil) if ticket.resolution == "obsolete"
        ticket.save!
        ticket
      end
    end

    def current?(entry)
      return false unless entry[:status] == "tracking"
      path = entry[:metadata]["specification_path"]
      return false unless path
      specification = @store.read(path)
      specification[:status].in?(%w[approved accepted final]) && specification[:source_hash] == entry[:metadata]["specification_revision"]
    end

    def tracker_entries
      @store.entries.select { |entry| entry[:artifact_type] == "plan_tracker" && entry[:metadata].key?("ticket_keys") }
    end

    def pending_for(entry)
      keys = entry[:metadata]["ticket_keys"]
      unless keys.is_a?(Array) && keys.all? { |key| key.is_a?(String) && Ticket::TICKET_KEY_PATTERN.match?(key) }
        raise Error, "Invalid ticket references in an internal tracker."
      end
      by_key = Ticket.for_project(@project.id).where(ticket_key: keys).index_by(&:ticket_key)
      keys.filter_map do |key|
        ticket = by_key[key]
        raise Error, "An internal tracker references a missing ticket: #{key}" unless ticket
        ticket unless ticket.workflow_status.in?(%w[solved closed]) || ticket.archived_at.present?
      end
    end
  end
end
