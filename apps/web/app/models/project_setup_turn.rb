require "json"

class ProjectSetupTurn < ApplicationRecord
  belongs_to :project_setup_session

  validates :turn_index, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :turn_index, uniqueness: { scope: :project_setup_session_id }
  validates :source_channel, presence: true
  validates :question, presence: true
  validates :answer, presence: true
  validates :normalized_fields_json, presence: true

  before_validation :set_defaults

  def normalized_fields
    parsed = JSON.parse(normalized_fields_json.to_s)
    parsed.is_a?(Hash) ? parsed : {}
  rescue JSON::ParserError
    {}
  end

  def normalized_fields=(value)
    fields = value.is_a?(Hash) ? value.transform_keys(&:to_s) : {}
    self.normalized_fields_json = JSON.generate(fields)
  end

  def to_saga_turn
    {
      "turn_index" => turn_index,
      "question" => question,
      "answer" => answer,
      "normalized_fields" => normalized_fields,
      "source_channel" => source_channel,
      "request_id" => request_id,
      "created_at" => created_at&.iso8601
    }
  end

  private

  def set_defaults
    self.source_channel = project_setup_session&.source_channel if source_channel.blank?
    self.normalized_fields_json = "{}" if normalized_fields_json.blank?
  end
end
