class TicketDocumentLink < ApplicationRecord
  ROLES = %w[reference primary_spec plan_tracker].freeze

  belongs_to :ticket
  belongs_to :document

  validates :role, inclusion: { in: ROLES }
  validates :document_id, uniqueness: { scope: :ticket_id }
end
