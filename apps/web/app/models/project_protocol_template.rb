require "json"

class ProjectProtocolTemplate < ApplicationRecord
  TEMPLATE_KINDS = %w[common stack].freeze
  STATUSES = %w[active archived].freeze

  has_many :documents,
           -> { order(:position, :id) },
           class_name: "ProjectProtocolTemplateDocument",
           dependent: :delete_all,
           inverse_of: :project_protocol_template

  validates :template_kind, inclusion: {in: TEMPLATE_KINDS}
  validates :status, inclusion: {in: STATUSES}
  validates :key, presence: true, uniqueness: {scope: :template_kind}
  validates :name, presence: true

  before_validation :set_defaults

  def matchers
    parsed = JSON.parse(matchers_json.to_s)
    parsed.is_a?(Array) ? parsed.map(&:to_s) : []
  rescue JSON::ParserError
    []
  end

  def matchers=(value)
    self.matchers_json = JSON.generate(Array(value).map(&:to_s).reject(&:empty?).uniq)
  end

  def common?
    template_kind == "common"
  end

  def stack?
    template_kind == "stack"
  end

  private

  def set_defaults
    self.status = "active" if status.blank?
    self.matchers_json = "[]" if matchers_json.blank?
  end
end
