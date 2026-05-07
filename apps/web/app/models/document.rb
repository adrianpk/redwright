class Document < ApplicationRecord
  TYPES = %w[draft spec plan_tracker].freeze
  EDITABLE_TYPES = %w[draft].freeze

  belongs_to :project
  belongs_to :use_case, optional: true
  belongs_to :source_draft, class_name: "Document", optional: true

  has_many :derived_specs,
           class_name: "Document",
           foreign_key: :source_draft_id,
           inverse_of: :source_draft,
           dependent: :nullify

  has_many :outgoing_relations,
           class_name: "DocumentRelation",
           foreign_key: :from_artifact_id,
           inverse_of: :from_artifact,
           dependent: :destroy
  has_many :incoming_relations,
           class_name: "DocumentRelation",
           foreign_key: :to_artifact_id,
           inverse_of: :to_artifact,
           dependent: :destroy

  validates :artifact_type, inclusion: { in: TYPES }
  validates :title, presence: true
  validates :body, presence: true
  validate :use_case_belongs_to_project
  validate :source_draft_contract
  validate :editable_policy_contract
  validate :lifecycle_transition_contract, on: :update

  scope :by_type, ->(type) { where(artifact_type: type) }
  scope :for_project, ->(project_id) { where(project_id: project_id) }
  scope :for_use_case, ->(use_case_id) { where(use_case_id: use_case_id) }

  def related_documents
    outgoing = outgoing_relations.includes(:to_artifact).map do |relation|
      [relation.relation_type, relation.to_artifact]
    end
    incoming = incoming_relations.includes(:from_artifact).map do |relation|
      [relation.relation_type, relation.from_artifact]
    end
    (outgoing + incoming).uniq { |relation_type, artifact| [relation_type, artifact.id] }
  end

  alias_method :related_artifacts, :related_documents

  private

  def source_draft_contract
    if artifact_type == "spec"
      errors.add(:source_draft, "is required for spec artifacts") unless source_draft
    elsif source_draft_id.present?
      errors.add(:source_draft, "is only valid for spec artifacts")
    end

    if source_draft && source_draft.artifact_type != "draft"
      errors.add(:source_draft, "must reference a draft artifact")
    end

    return unless source_draft && project_id && source_draft.project_id != project_id

    errors.add(:source_draft, "must belong to the same project")
  end

  def editable_policy_contract
    if EDITABLE_TYPES.include?(artifact_type)
      errors.add(:editable, "must be true for draft artifacts") if editable != true
    elsif editable != false
      errors.add(:editable, "must be false for non-draft artifacts")
    end
  end

  def lifecycle_transition_contract
    return unless artifact_type_changed?

    errors.add(:artifact_type, "is immutable after creation")
  end

  def use_case_belongs_to_project
    return unless use_case
    return if use_case.project_id == project_id

    errors.add(:use_case, "must belong to the same project")
  end
end
