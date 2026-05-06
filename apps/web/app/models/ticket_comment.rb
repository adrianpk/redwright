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
    MentionParser.new(comment: self).call
  end

  class MentionParser
    TARGET_TYPES = {
      user: "user",
      agent: "agent",
      unresolved: "unresolved"
    }.freeze
    HANDLE_PATTERN = /(?<![\w.])@([A-Za-z0-9][A-Za-z0-9_.-]*)/.freeze

    def initialize(comment:)
      @comment = comment
    end

    def call
      handles.each do |handle|
        comment.mentions.create!(mention_attrs_for(handle))
      end
    end

    private

    attr_reader :comment

    def handles
      comment.body.to_s.scan(HANDLE_PATTERN).flatten.map { |handle| handle.downcase.sub(/[.]+$/, "") }.uniq
    end

    def mention_attrs_for(handle)
      user = user_for(handle)
      return user_attrs(handle, user) if user
      return agent_attrs(handle) if handle.start_with?("agent")

      {
        ticket: comment.ticket,
        target_type: TARGET_TYPES.fetch(:unresolved),
        target_id: nil,
        handle: handle,
        display_label: "@#{handle}"
      }
    end

    def user_attrs(handle, user)
      {
        ticket: comment.ticket,
        target_type: TARGET_TYPES.fetch(:user),
        target_id: user.id,
        handle: handle,
        display_label: user.email_address
      }
    end

    def agent_attrs(handle)
      {
        ticket: comment.ticket,
        target_type: TARGET_TYPES.fetch(:agent),
        target_id: nil,
        handle: handle,
        display_label: "@#{handle}"
      }
    end

    def user_for(handle)
      User.find_each.find do |user|
        user.email_address.to_s.split("@").first.downcase == handle
      end
    end
  end
end
