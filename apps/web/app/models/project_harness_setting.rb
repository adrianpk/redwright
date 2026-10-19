class ProjectHarnessSetting < ApplicationRecord
  PROFILE_KEY = /\A[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}\z/
  MAX_RECEIPTS = 128
  belongs_to :project
  belongs_to :changed_by, class_name: "User", optional: true

  validates :project_id, uniqueness: true
  validates :authoring_profile, :ticket_proposal_profile, format: {with: PROFILE_KEY}, allow_nil: true
  validates :lock_version, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validate :valid_receipts

  def receipts
    JSON.parse(mutation_receipts_json)
  end

  def public_state
    {"project_id" => project_id, "authoring_profile" => authoring_profile,
      "ticket_proposal_profile" => ticket_proposal_profile, "revision" => lock_version,
      "changed_by" => changed_by_id, "changed_at" => changed_at&.iso8601(6)}
  end

  def as_json(*)
    public_state
  end

  private

  def valid_receipts
    values = receipts
    unless values.is_a?(Array) && values.size <= MAX_RECEIPTS && mutation_receipts_json.bytesize <= 128 * 1024 &&
        values.all? { |item| item.is_a?(Hash) && item.keys.sort == %w[digest expires_at request_id result] &&
          item["request_id"].is_a?(String) && item["request_id"].bytesize.between?(1, 128) &&
          /\A[0-9a-f]{64}\z/.match?(item["digest"].to_s) && item["result"].is_a?(Hash) &&
          item["expires_at"].is_a?(String) && Time.iso8601(item["expires_at"]) }
      errors.add(:mutation_receipts_json, "must contain bounded selection receipts")
    end
  rescue JSON::ParserError, TypeError, ArgumentError
    errors.add(:mutation_receipts_json, "must contain valid selection receipts")
  end
end
