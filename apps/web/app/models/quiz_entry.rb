class QuizEntry < ApplicationRecord
  STATUSES = %w[answered skipped incomplete].freeze

  belongs_to :quiz

  validates :question, presence: true
  validates :answer, presence: true, if: :answered?
  validates :status, inclusion: { in: STATUSES }

  def answered?
    status == "answered"
  end

  def skipped?
    status == "skipped"
  end
end
