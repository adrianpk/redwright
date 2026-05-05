class UseCase < ApplicationRecord
  belongs_to :project

  before_validation :normalize_slug

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :project_id }

  private

  def normalize_slug
    source = slug.presence || name
    self.slug = source.to_s
                      .downcase
                      .gsub(/[^a-z0-9]+/, "-")
                      .gsub(/\A-+|-+\z/, "")
  end
end
