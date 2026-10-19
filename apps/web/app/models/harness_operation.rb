class HarnessOperation < ApplicationRecord
  PURPOSES = %w[specification slicing curation references ticket_proposal].freeze
  STATES = %w[prepared running completed failed cancelled timed_out uncertain].freeze
  TERMINAL_STATES = %w[completed failed cancelled timed_out].freeze
  IMMUTABLE_FIELDS = %w[project_id operation_key purpose role selection_revision binding_json binding_digest contract_digest workspace_revision_json private_run_ref].freeze

  belongs_to :project
  attr_readonly(*IMMUTABLE_FIELDS)
  validates :operation_key, presence: true, length: {maximum: 128}, uniqueness: {scope: :project_id}
  validates :purpose, inclusion: {in: PURPOSES}
  validates :role, inclusion: {in: %w[authoring ticket_proposal]}
  validates :state, inclusion: {in: STATES}
  validates :selection_revision, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :binding_digest, :contract_digest, format: {with: /\A[0-9a-f]{64}\z/}
  validates :private_run_ref, format: {with: /\A[0-9a-f-]{36}\z/}
  validate :valid_retained_data

  def binding
    JSON.parse(binding_json, freeze: true)
  end

  def attempts
    JSON.parse(attempts_json)
  end

  def referenced?
    attempts.any? { |attempt| attempt["artifact_ref"].present? || attempt["application_receipt"].present? }
  end

  def public_state
    {"id" => id, "operation_key" => operation_key, "purpose" => purpose, "role" => role, "state" => state,
      "selection_revision" => selection_revision, "binding_digest" => binding_digest,
      "contract_digest" => contract_digest, "binding" => binding.except("workspace_ref")}
  end

  def as_json(*)
    public_state
  end

  private

  def valid_retained_data
    value = binding
    workspace = JSON.parse(workspace_revision_json)
    history = attempts
    valid = value.is_a?(Hash) && value["schema_version"] == "harness-binding/v1" &&
      binding_json.bytesize <= 16 * 1024 && Digest::SHA256.hexdigest(binding_json) == binding_digest &&
      workspace.is_a?(Hash) && workspace_revision_json.bytesize <= 16 * 1024 &&
      history.is_a?(Array) && history.size <= (role == "ticket_proposal" ? 3 : 1) &&
      history.all? { |item| item.is_a?(Hash) } && attempts_json.bytesize <= 64 * 1024 &&
      (purpose == "ticket_proposal") == (role == "ticket_proposal") && operation_key.to_s.bytesize.between?(1, 128)
    errors.add(:base, "invalid retained harness data") unless valid
  rescue JSON::ParserError, TypeError
    errors.add(:base, "invalid retained harness JSON")
  end
end
