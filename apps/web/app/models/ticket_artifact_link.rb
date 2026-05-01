class TicketArtifactLink < ApplicationRecord
  ROLES = %w[reference primary_spec plan_tracker].freeze

  belongs_to :ticket
  belongs_to :document_artifact

  validates :role, inclusion: { in: ROLES }
  validates :document_artifact_id, uniqueness: { scope: :ticket_id }
end
