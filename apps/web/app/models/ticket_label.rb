class TicketLabel < ApplicationRecord
  belongs_to :ticket
  belongs_to :label

  validates :ticket_id, uniqueness: { scope: :label_id }
end
