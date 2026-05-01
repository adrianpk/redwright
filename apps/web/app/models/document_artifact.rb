class DocumentArtifact < ApplicationRecord
  TYPES = %w[draft spec plan_tracker].freeze

  belongs_to :source_draft, class_name: "DocumentArtifact", optional: true

  has_many :derived_specs,
           class_name: "DocumentArtifact",
           foreign_key: :source_draft_id,
           inverse_of: :source_draft,
           dependent: :nullify

  has_many :outgoing_relations,
           class_name: "DocumentArtifactRelation",
           foreign_key: :from_artifact_id,
           inverse_of: :from_artifact,
           dependent: :destroy
  has_many :incoming_relations,
           class_name: "DocumentArtifactRelation",
           foreign_key: :to_artifact_id,
           inverse_of: :to_artifact,
           dependent: :destroy
  has_many :ticket_artifact_links, dependent: :destroy
  has_many :tickets, through: :ticket_artifact_links

  validates :artifact_type, inclusion: { in: TYPES }
  validates :title, presence: true
  validates :body, presence: true
  validate :source_draft_contract

  scope :by_type, ->(type) { where(artifact_type: type) }

  def related_artifacts
    outgoing = outgoing_relations.includes(:to_artifact).map do |relation|
      [relation.relation_type, relation.to_artifact]
    end
    incoming = incoming_relations.includes(:from_artifact).map do |relation|
      [relation.relation_type, relation.from_artifact]
    end
    (outgoing + incoming).uniq { |relation_type, artifact| [relation_type, artifact.id] }
  end

  private

  def source_draft_contract
    if artifact_type == "spec"
      errors.add(:source_draft, "is required for spec artifacts") unless source_draft
    elsif source_draft_id.present?
      errors.add(:source_draft, "is only valid for spec artifacts")
    end

    return unless source_draft && source_draft.artifact_type != "draft"

    errors.add(:source_draft, "must reference a draft artifact")
  end
end
