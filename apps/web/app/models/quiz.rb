class Quiz < ApplicationRecord
  STATUSES = %w[active paused archived].freeze

  belongs_to :project
  belongs_to :use_case, optional: true

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :project_id, uniqueness: { conditions: -> { where(use_case_id: nil) }, if: -> { use_case_id.nil? } }
  validates :use_case_id, uniqueness: { scope: :project_id }, allow_nil: true
  validate :use_case_belongs_to_project

  scope :project_level, -> { where(use_case_id: nil) }
  scope :for_use_case, ->(use_case_id) { where(use_case_id: use_case_id) }

  private

  def use_case_belongs_to_project
    return unless use_case
    return if use_case.project_id == project_id

    errors.add(:use_case, "must belong to the same project")
  end
end
