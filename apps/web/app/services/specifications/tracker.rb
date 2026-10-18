module Specifications
  class Tracker
    def initialize(project:)
      @project = project
      @store = FileStore.new(project)
    end

    def generate!(specification:, tickets:)
      raise Error, "Approve the specification before organizing implementation." unless specification.status.in?(%w[approved accepted final])
      tickets = tickets.to_a
      unless specification.project_id == @project.id && tickets.all? { |ticket| ticket.project_id == @project.id }
        raise Error, "Tracker references must belong to the same project."
      end
      path = specification.relative_path.sub("/spec/", "/tracker/")
      raise Error, "Tracker generation requires a canonical specification path." if path == specification.relative_path
      revision = @store.read(path)[:source_hash] if @store.root.join(path).file?
      @store.write(path: path, revision: revision, metadata: {
        "title" => "#{specification.title} execution", "artifact_type" => "plan_tracker", "status" => "tracking",
        "project_id" => @project.id.to_s, "case_slug" => specification.use_case&.slug.to_s,
        "specification_path" => specification.relative_path, "ticket_keys" => tickets.map(&:ticket_key), "created_at" => Time.current.iso8601
      }, body: "# #{specification.title} execution\n\n## Tickets\n\n" + tickets.map { |ticket| "- #{ticket.ticket_key}: #{ticket.title}" }.join("\n"))
    end

    def pending_tickets
      tracker_entries.flat_map { |entry| pending_for(entry) }.uniq(&:id)
    end

    def pick(scope)
      return scope.ordered_for_board.first unless @store.root.directory?
      entries = tracker_entries
      return scope.ordered_for_board.first if entries.empty?
      first_pending = entries.filter_map { |entry| pending_for(entry).first }
      ids = first_pending.map(&:id)
      eligible = scope.where(id: ids).pluck(:id)
      selected = first_pending.find { |ticket| eligible.include?(ticket.id) }
      return selected if selected
      tracked_keys = entries.flat_map { |entry| Array(entry[:metadata]["ticket_keys"]) }
      scope.where.not(ticket_key: tracked_keys).ordered_for_board.first
    end

    private

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
