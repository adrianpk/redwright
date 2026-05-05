class QuizEntry < ApplicationRecord
  STATUSES = %w[answered skipped incomplete].freeze

  belongs_to :quiz
  belongs_to :project
  belongs_to :use_case, optional: true
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  before_validation :assign_scope_from_quiz

  validates :question, presence: true
  validates :answer, presence: true, if: :answered?
  validates :status, inclusion: { in: STATUSES }
  validate :scope_matches_quiz

  def answered?
    status == "answered"
  end

  def skipped?
    status == "skipped"
  end

  def tag_with!(*names)
    names.flatten.filter_map do |name|
      next if Tag.normalize_name(name).blank?

      tag = Tag.find_or_create_normalized!(name)
      taggings.find_or_create_by!(tag: tag)
      tag
    end
  end

  private

  def assign_scope_from_quiz
    return unless quiz

    self.project ||= quiz.project
    self.use_case ||= quiz.use_case
  end

  def scope_matches_quiz
    return unless quiz
    errors.add(:project, "must match quiz project") if project_id != quiz.project_id
    errors.add(:use_case, "must match quiz use case") if use_case_id != quiz.use_case_id
  end
end
