class TicketCommentMention < ApplicationRecord
  TARGET_TYPES = %w[user agent unresolved].freeze

  belongs_to :ticket_comment
  belongs_to :ticket

  validates :target_type, inclusion: { in: TARGET_TYPES }
  validates :handle, presence: true
  validate :ticket_matches_comment

  private

  def ticket_matches_comment
    return unless ticket_comment && ticket
    return if ticket_comment.ticket_id == ticket_id

    errors.add(:ticket, "must match the comment ticket")
  end
end
