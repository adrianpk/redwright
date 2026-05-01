class DocumentArtifactRelation < ApplicationRecord
  RELATION_TYPES = %w[derives_from references tracks].freeze

  belongs_to :from_artifact, class_name: "DocumentArtifact"
  belongs_to :to_artifact, class_name: "DocumentArtifact"

  validates :relation_type, inclusion: { in: RELATION_TYPES }
  validates :to_artifact_id, uniqueness: { scope: [ :from_artifact_id, :relation_type ] }
  validate :prevent_self_reference

  private

  def prevent_self_reference
    return unless from_artifact_id.present? && from_artifact_id == to_artifact_id

    errors.add(:to_artifact, "must be different from from_artifact")
  end
end
