class TicketDocumentLink < ApplicationRecord
  ROLES = %w[reference primary_spec plan_tracker].freeze

  belongs_to :ticket
  belongs_to :document

  validates :role, inclusion: { in: ROLES }
  validates :document_id, uniqueness: { scope: :ticket_id }
  validate :project_consistency
  validate :role_document_type_contract

  private

  def project_consistency
    return unless ticket && document
    return if ticket.project_id == document.project_id

    errors.add(:document, "must belong to the same project as ticket")
  end

  def role_document_type_contract
    return unless document

    case role
    when "primary_spec"
      errors.add(:role, "requires a spec document") unless document.artifact_type == "spec"
    when "plan_tracker"
      errors.add(:role, "requires a plan_tracker document") unless document.artifact_type == "plan_tracker"
    end
  end
end
