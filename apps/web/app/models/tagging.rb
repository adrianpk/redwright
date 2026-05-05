class Tagging < ApplicationRecord
  belongs_to :tag
  belongs_to :taggable, polymorphic: true
  belongs_to :project
  belongs_to :use_case, optional: true

  before_validation :assign_scope_from_taggable

  validates :tag_id, uniqueness: {scope: [ :taggable_type, :taggable_id ]}
  validate :scope_matches_taggable

  scope :for_project, ->(project) { where(project_id: project) }
  scope :for_use_case, ->(use_case) { where(use_case_id: use_case) }
  scope :with_tag_names, ->(*names) {
    normalized = names.flatten.map { |name| Tag.normalize_name(name) }.reject(&:blank?)
    joins(:tag).where(tags: {name: normalized})
  }

  private

  def assign_scope_from_taggable
    return unless taggable

    self.project ||= taggable.project if taggable.respond_to?(:project)
    self.use_case ||= taggable.use_case if taggable.respond_to?(:use_case)
  end

  def scope_matches_taggable
    return unless taggable

    if taggable.respond_to?(:project_id) && project_id.present? && taggable.project_id != project_id
      errors.add(:project, "must match taggable project")
    end

    if taggable.respond_to?(:use_case_id) && use_case_id.present? && taggable.use_case_id != use_case_id
      errors.add(:use_case, "must match taggable use case")
    end
  end
end
