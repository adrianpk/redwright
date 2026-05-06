class UseCase < ApplicationRecord
  belongs_to :project
  has_one :quiz, dependent: :restrict_with_error
  has_many :quiz_entries, dependent: :restrict_with_error
  has_many :tickets, dependent: :restrict_with_error
  has_many :documents, dependent: :restrict_with_error
  has_many :taggings, dependent: :restrict_with_error

  before_validation :normalize_slug

  validates :name, presence: true
  validates :name, uniqueness: { scope: :project_id }
  validates :description, presence: true
  validates :slug, presence: true, uniqueness: { scope: :project_id }

  def find_or_create_quiz!
    quiz || project.quizzes.create!(use_case: self, name: "#{name} Quiz")
  end

  def blocking_reference_counts
    {
      "tickets" => tickets.count,
      "documents" => documents.count,
      "quiz" => quiz ? 1 : 0,
      "quiz_entries" => quiz_entries.count,
      "taggings" => taggings.count
    }
  end

  def deletion_blocked?
    blocking_reference_counts.values.any?(&:positive?)
  end

  private

  def normalize_slug
    source = slug.presence || name
    self.slug = source.to_s
                      .downcase
                      .gsub(/[^a-z0-9]+/, "-")
                      .gsub(/\A-+|-+\z/, "")
  end
end
