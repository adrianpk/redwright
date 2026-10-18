class Document < ApplicationRecord
  TYPES = %w[spec plan_tracker internal].freeze
  belongs_to :project
  belongs_to :use_case, optional: true
  has_many :outgoing_relations, class_name: "DocumentRelation", foreign_key: :from_artifact_id, dependent: :destroy
  has_many :incoming_relations, class_name: "DocumentRelation", foreign_key: :to_artifact_id, dependent: :destroy

  attr_writer :body
  attr_accessor :revision, :provenance
  validates :title, :body, :status, presence: true
  validates :artifact_type, inclusion: {in: TYPES}
  validates :status, inclusion: {in: %w[draft approved accepted final]}, if: :specification?
  validate :same_project_use_case
  validate :immutable_kind
  validate :delivery_owner_is_stable
  validates :use_case, presence: true, if: :specification?
  validates :artifact_type, uniqueness: {scope: :use_case_id}, if: -> { use_case_id.present? && artifact_type.in?(%w[spec plan_tracker]) }
  before_validation :assign_defaults
  before_save :persist_source

  scope :specifications, -> { where(artifact_type: "spec") }
  scope :by_type, ->(type) { where(artifact_type: type) }
  scope :for_project, ->(id) { where(project_id: id) }
  scope :for_use_case, ->(id) { where(use_case_id: id) }

  def self.reconcile!(project)
    Ticket.reconcile!(project)
    entries = Specifications::FileStore.new(project).entries
    if entries.any? { |entry| entry[:artifact_type] == "spec" && entry[:use_case_id].nil? }
      raise Specifications::Error, "Feature specifications need a valid case_slug in their file metadata."
    end
    grouped = entries.select { |entry| entry[:use_case_id] && entry[:artifact_type].in?(%w[spec plan_tracker]) }.group_by { |entry| [entry[:use_case_id], entry[:artifact_type]] }
    raise Specifications::Error, "A feature can have only one specification and one tracker." if grouped.values.any? { |group| group.size > 1 }
    entries.select { |entry| entry[:artifact_type] == "spec" }.each do |entry|
      if Ticket.for_project(project.id).where(specification_path: entry[:path]).where.not(use_case_id: entry[:use_case_id]).exists?
        raise Specifications::Error, "A sliced specification cannot move to another feature."
      end
      tracker = entries.find { |candidate| candidate[:artifact_type] == "plan_tracker" && candidate[:metadata]["specification_path"] == entry[:path] }
      if tracker&.dig(:metadata, "execution_started_at").present? && tracker[:metadata]["specification_revision"] != entry[:source_hash]
        raise Specifications::Error, "A specification changed after execution started. Restore its execution revision and create a corrective feature."
      end
    end
    transaction do
      entries.each do |entry|
        document = project.documents.find_by(relative_path: entry[:path])
        values = entry.slice(:title, :artifact_type, :status, :use_case_id, :source_hash, :source_modified_at)
        if !document
          insert_all!([values.merge(project_id: project.id, relative_path: entry[:path], created_at: Time.current, updated_at: Time.current)])
        elsif values.any? { |key, value| document.public_send(key) != value }
          document.update_columns(values.merge(updated_at: Time.current))
        end
      end
      project.documents.where.not(relative_path: entries.map { |entry| entry[:path] }).each do |missing|
        if Ticket.for_project(project.id).where("specification_path = ? OR tracker_path = ?", missing.relative_path, missing.relative_path).exists?
          raise Specifications::Error, "A delivery document is missing. Restore its file before continuing."
        end
        missing.destroy!
      end
      DocumentRelation.where(from_artifact_id: project.documents.select(:id)).delete_all
      by_path = project.documents.index_by(&:relative_path)
      entries.each do |entry|
        Array(entry[:metadata]["relations"]).uniq.each do |relation|
          target = by_path[relation["path"]]
          source = by_path[entry[:path]]
          next unless target && source && target != source && DocumentRelation::RELATION_TYPES.include?(relation["type"])
          DocumentRelation.insert_all!([{from_artifact_id: source.id, to_artifact_id: target.id, relation_type: relation["type"], created_at: Time.current, updated_at: Time.current}])
        end
      end
    end
    project.documents
  end

  def specification?
    artifact_type == "spec"
  end

  def body
    return @body if defined?(@body)
    relative_path.present? ? source.fetch(:body) : nil
  end

  def source
    Specifications::FileStore.new(project).read(relative_path)
  end

  def approve!(revision:)
    raise Specifications::Error, "Only a draft specification can be approved." unless specification? && status == "draft"
    self.revision = revision
    update!(status: "approved")
    self
  end

  def revise!(attributes:, revision:)
    Features::Workflow.new(use_case).with_lock do
      Features::Workflow.new(use_case).ensure_mutable!
      self.revision = revision
      update!(attributes)
      Features::Workflow.new(use_case).invalidate_tracker!
    end
    self
  end

  def related_documents
    outgoing_relations.includes(:to_artifact).map { |edge| [edge.relation_type, edge.to_artifact] } +
      incoming_relations.includes(:from_artifact).map { |edge| [edge.relation_type, edge.from_artifact] }
  end
  alias_method :related_artifacts, :related_documents

  private

  def immutable_kind
    errors.add(:artifact_type, "cannot be changed") if persisted? && artifact_type_changed?
  end

  def delivery_owner_is_stable
    if persisted? && specification? && use_case_id_changed? && Ticket.for_project(project_id).where(specification_path: relative_path).exists?
      errors.add(:use_case, "cannot change after slicing")
    end
  end

  def assign_defaults
    self.artifact_type ||= "spec"
    self.status ||= specification? ? "draft" : "tracking"
  end

  def same_project_use_case
    errors.add(:use_case, "must belong to the same project") if use_case && use_case.project_id != project_id
  end

  def persist_source
    Features::Workflow.new(use_case).ensure_mutable! if specification? && use_case
    store = Specifications::FileStore.new(project)
    metadata = relative_path.present? ? source[:metadata] : {}
    metadata.merge!(provenance.stringify_keys) if provenance
    metadata.merge!("title" => title, "project_id" => metadata["project_id"].presence || project_id.to_s, "case_slug" => use_case&.slug.to_s, "status" => status,
      "artifact_type" => artifact_type, "created_at" => metadata["created_at"] || Time.current.iso8601)
    entry = store.write(path: relative_path, metadata: metadata, body: body, revision: revision.presence || source_hash)
    self.relative_path = entry[:path]
    self.source_hash = entry[:source_hash]
    self.source_modified_at = entry[:source_modified_at]
    remove_instance_variable(:@body) if defined?(@body)
  end
end
