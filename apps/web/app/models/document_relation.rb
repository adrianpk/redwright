class DocumentRelation < ApplicationRecord
  RELATION_TYPES = %w[derives_from references tracks].freeze

  belongs_to :from_artifact, class_name: "Document"
  belongs_to :to_artifact, class_name: "Document"

  validates :relation_type, inclusion: { in: RELATION_TYPES }
  validates :to_artifact_id, uniqueness: { scope: [ :from_artifact_id, :relation_type ] }
  validate :prevent_self_reference
  validate :same_project
  after_create :persist_reference

  private

  def persist_reference
    entry = Specifications::FileStore.new(from_artifact.project).add_relation(from_artifact, to_artifact, relation_type)
    from_artifact.update_columns(source_hash: entry[:source_hash], source_modified_at: entry[:source_modified_at])
  end

  def same_project
    if from_artifact && to_artifact && from_artifact.project_id != to_artifact.project_id
      errors.add(:to_artifact, "must belong to the same project")
    end
  end

  def prevent_self_reference
    return unless from_artifact_id.present? && from_artifact_id == to_artifact_id

    errors.add(:to_artifact, "must be different from from_artifact")
  end
end
