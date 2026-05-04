require "json"

class ProjectProtocolDocument < ApplicationRecord
  LAYERS = %w[behavioral stack].freeze

  belongs_to :project_protocol

  validates :key, presence: true, uniqueness: {scope: :project_protocol_id}
  validates :path, presence: true, uniqueness: {scope: :project_protocol_id}
  validates :title, presence: true
  validates :layer, inclusion: {in: LAYERS}
  validates :position, presence: true

  before_validation :set_defaults
  after_save :materialize_filesystem
  after_destroy :materialize_filesystem

  def provenance
    parsed = JSON.parse(provenance_json.to_s)
    parsed.is_a?(Hash) ? parsed : {}
  rescue JSON::ParserError
    {}
  end

  def provenance=(value)
    self.provenance_json = JSON.generate(normalize_hash(value))
  end

  def to_state
    {
      "id" => id,
      "project_protocol_id" => project_protocol_id,
      "key" => key,
      "path" => path,
      "title" => title,
      "layer" => layer,
      "position" => position,
      "body" => body,
      "provenance" => provenance,
      "created_at" => created_at&.iso8601,
      "updated_at" => updated_at&.iso8601
    }
  end

  private

  def set_defaults
    self.position = 0 if position.nil?
    self.body = "" if body.nil?
    self.provenance_json = "{}" if provenance_json.blank?
  end

  def normalize_hash(value)
    return {} unless value.is_a?(Hash)

    value.each_with_object({}) do |(key, item), hash|
      hash[key.to_s] =
        case item
        when Hash
          normalize_hash(item)
        when Array
          item.map { |entry| entry.is_a?(Hash) ? normalize_hash(entry) : entry }
        else
          item
        end
    end
  end

  def materialize_filesystem
    return unless project_protocol

    ProjectProtocols::FilesystemMaterializer.new(project: project_protocol.project).call(update_manifest: true)
  end
end
