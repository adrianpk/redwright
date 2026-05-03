class ProjectProtocol < ApplicationRecord
  STATUSES = %w[draft active archived].freeze

  belongs_to :project
  has_many :documents,
           -> { order(:position, :id) },
           class_name: "ProjectProtocolDocument",
           dependent: :delete_all,
           inverse_of: :project_protocol

  validates :status, inclusion: {in: STATUSES}

  before_validation :set_defaults

  def self.missing_state_for(project)
    {
      "id" => nil,
      "project_id" => project.id,
      "status" => "missing",
      "documents" => [],
      "created_at" => nil,
      "updated_at" => nil
    }
  end

  def to_state
    {
      "id" => id,
      "project_id" => project_id,
      "status" => status,
      "documents" => documents.map(&:to_state),
      "created_at" => created_at&.iso8601,
      "updated_at" => updated_at&.iso8601
    }
  end

  private

  def set_defaults
    self.status = "draft" if status.blank?
  end
end
