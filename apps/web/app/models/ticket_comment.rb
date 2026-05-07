class TicketComment < ApplicationRecord
  AUTHOR_TYPES = %w[user agent unknown].freeze

  belongs_to :ticket
  has_many :mentions, class_name: "TicketCommentMention", dependent: :destroy

  validates :author_type, inclusion: { in: AUTHOR_TYPES }
  validates :author_label, presence: true
  validates :body, presence: true

  after_create :capture_mentions

  scope :chronological, -> { order(:created_at, :id) }

  private

  def capture_mentions
    TicketManagement::MentionCaptureService.new(comment: self).call
  end
end
