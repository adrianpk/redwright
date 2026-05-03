class ProjectProtocolTemplateDocument < ApplicationRecord
  LAYERS = %w[behavioral stack].freeze

  belongs_to :project_protocol_template

  validates :key, presence: true, uniqueness: {scope: :project_protocol_template_id}
  validates :path, presence: true, uniqueness: {scope: :project_protocol_template_id}
  validates :title, presence: true
  validates :layer, inclusion: {in: LAYERS}
  validates :position, presence: true
  validates :body, presence: true

  before_validation :set_defaults

  private

  def set_defaults
    self.position = 0 if position.nil?
  end
end
