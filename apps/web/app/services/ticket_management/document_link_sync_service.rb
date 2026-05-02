module TicketManagement
  class DocumentLinkSyncService
    def self.role_for(document)
      case document.artifact_type
      when "spec"
        "primary_spec"
      when "plan_tracker"
        "plan_tracker"
      else
        "reference"
      end
    end

    def initialize(ticket:, document_ids:)
      @ticket = ticket
      @document_ids = Array(document_ids).map(&:to_i).select(&:positive?).uniq
    end

    def call
      current_links = ticket.ticket_document_links.index_by(&:document_id)
      remove_ids = current_links.keys - document_ids

      ticket.ticket_document_links.where(document_id: remove_ids).delete_all if remove_ids.any?

      Document.where(id: document_ids).find_each do |document|
        link = current_links[document.id]
        role = self.class.role_for(document)

        if link
          link.update!(role: role) if link.role != role
        else
          ticket.ticket_document_links.create!(document: document, role: role)
        end
      end

      ticket.reload
    end

    private

    attr_reader :ticket, :document_ids
  end
end
