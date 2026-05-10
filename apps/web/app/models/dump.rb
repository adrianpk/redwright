require "securerandom"

class Dump < ApplicationRecord
  STATUSES = %w[active completed cancelled archived].freeze
  CAPTURE_STATUSES = %w[capturing closed].freeze
  CURATION_STATUSES = %w[not_curated curating curated needs_review].freeze

  belongs_to :project
  belongs_to :use_case, optional: true
  has_many :entries, class_name: "DumpEntry", dependent: :destroy

  before_validation :assign_default_title
  before_validation :normalize_slug

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: { scope: :project_id }
  validates :status, inclusion: { in: STATUSES }
  validates :capture_status, inclusion: { in: CAPTURE_STATUSES }
  validates :curation_status, inclusion: { in: CURATION_STATUSES }
  validate :use_case_belongs_to_project

  scope :project_level, -> { where(use_case_id: nil) }
  scope :for_use_case, ->(use_case_id) { where(use_case_id: use_case_id) }
  scope :curated, -> { where(curation_status: "curated") }

  def capturing?
    capture_status == "capturing"
  end

  def curated?
    curation_status == "curated"
  end

  def to_param
    slug
  end

  private

  def assign_default_title
    self.title = "Untitled Dump #{SecureRandom.hex(4)}" if title.blank?
  end

  def normalize_slug
    source = slug.presence || title
    self.slug = source.to_s.parameterize
  end

  def use_case_belongs_to_project
    return unless use_case
    return if use_case.project_id == project_id

    errors.add(:use_case, "must belong to the same project")
  end
end
