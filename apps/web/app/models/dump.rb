class Dump < ApplicationRecord
  STATUSES = %w[draft ready archived].freeze

  belongs_to :project
  belongs_to :use_case, optional: true
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  attr_writer :body
  attr_accessor :revision

  before_validation :assign_defaults
  before_save :persist_source

  validates :title, :slug, :status, presence: true
  validates :status, inclusion: {in: STATUSES}
  validates :slug, uniqueness: {scope: :project_id}
  validates :use_case_id, uniqueness: true, allow_nil: true
  validate :use_case_belongs_to_project

  scope :project_level, -> { where(use_case_id: nil) }
  scope :for_use_case, ->(id) { where(use_case_id: id) }
  scope :available, -> { where.not(status: "archived") }

  def self.reconcile!(project)
    entries = Dumps::FileStore.new(project).entries
    owned = entries.select { |entry| entry[:use_case_id] }.group_by { |entry| entry[:use_case_id] }
    raise Specifications::Error, "A use case can have only one dump document." if owned.values.any? { |group| group.size > 1 }
    values = entries.map { |entry| index_values(entry) }
    raise Specifications::Error, "Dump slugs must be unique within a project." if values.group_by { |entry| entry[:slug] }.values.any? { |group| group.size > 1 }
    transaction do
      project.dumps.where.not(relative_path: entries.map { |entry| entry[:path] }).destroy_all
      entries.zip(values).each do |entry, attributes|
        dump = project.dumps.find_by(relative_path: entry[:path])
        if dump
          dump.update_columns(attributes.merge(updated_at: Time.current)) if attributes.any? { |key, value| dump.public_send(key) != value }
        else
          insert_all!([attributes.merge(project_id: project.id, created_at: Time.current, updated_at: Time.current)])
          dump = project.dumps.find_by!(relative_path: entry[:path])
        end
        dump.sync_tags!(Array(entry[:metadata]["tags"]))
      end
    end
    project.dumps.reset
  end

  def self.index_values(entry)
    entry.slice(:title, :status, :use_case_id, :source_hash, :source_modified_at).merge(
      relative_path: entry[:path],
      slug: entry[:metadata]["slug"].presence || (File.basename(entry[:path]) == "artifact.md" ? File.basename(File.dirname(entry[:path])) : File.basename(entry[:path], ".md")).parameterize
    )
  end

  def body
    return @body if defined?(@body)
    relative_path.present? ? source.fetch(:body) : ""
  end

  def source
    Dumps::FileStore.new(project).read(relative_path)
  end

  def to_param
    slug
  end

  def tag_with!(*names)
    normalized = names.flatten.map { |name| Tag.normalize_name(name) }.reject(&:blank?).uniq
    entry = source
    written = Dumps::FileStore.new(project).write(path: relative_path, metadata: entry[:metadata].merge("tags" => normalized), body: entry[:body], revision: entry[:source_hash])
    update_columns(self.class.index_values(written).merge(updated_at: Time.current))
    sync_tags!(normalized)
    tags.to_a
  end

  def sync_tags!(names)
    normalized = names.map { |name| Tag.normalize_name(name) }.reject(&:blank?).uniq
    taggings.where.not(tag_id: Tag.where(name: normalized).select(:id)).destroy_all
    taggings.update_all(use_case_id: use_case_id)
    normalized.each do |name|
      tag = Tag.find_or_create_normalized!(name)
      taggings.find_or_create_by!(tag: tag)
    end
  end

  private

  def assign_defaults
    self.title = use_case&.name || project&.name if title.blank?
    self.slug = (slug.presence || title).to_s.parameterize
    self.status ||= "draft"
  end

  def use_case_belongs_to_project
    errors.add(:use_case, "must belong to the same project") if use_case && use_case.project_id != project_id
  end

  def persist_source
    entry = source if relative_path.present?
    metadata = (entry&.dig(:metadata) || {}).merge(
      "artifact_type" => "dump", "title" => title, "slug" => slug, "status" => status,
      "project_id" => project_id.to_s, "case_slug" => use_case&.slug.to_s,
      "created_at" => entry&.dig(:metadata, "created_at") || Time.current.iso8601
    )
    written = Dumps::FileStore.new(project).write(path: relative_path, metadata: metadata, body: body, revision: revision.presence || source_hash)
    self.relative_path = written[:path]
    self.source_hash = written[:source_hash]
    self.source_modified_at = written[:source_modified_at]
    self.revision = nil
    remove_instance_variable(:@body) if defined?(@body)
  end
end
