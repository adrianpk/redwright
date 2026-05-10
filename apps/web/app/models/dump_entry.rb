class DumpEntry < ApplicationRecord
  belongs_to :dump
  belongs_to :project
  belongs_to :use_case, optional: true

  before_validation :assign_scope_from_dump
  before_validation :assign_position, on: :create
  before_validation :assign_default_polished_input

  validates :position, presence: true
  validates :raw_input, presence: true
  validates :polished_input, presence: true
  validate :scope_matches_dump

  scope :ordered, -> { order(:position, :created_at) }

  private

  def assign_scope_from_dump
    return unless dump

    self.project ||= dump.project
    self.use_case ||= dump.use_case
  end

  def assign_position
    return if position.present?
    return unless dump

    self.position = dump.entries.maximum(:position).to_i + 1
  end

  def assign_default_polished_input
    self.polished_input = raw_input.to_s.strip if polished_input.blank?
  end

  def scope_matches_dump
    return unless dump

    errors.add(:project, "must match dump project") if project_id != dump.project_id
    errors.add(:use_case, "must match dump use case") if use_case_id != dump.use_case_id
  end
end
