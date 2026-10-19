class HarnessOperation < ApplicationRecord
  PURPOSES = %w[specification slicing curation references ticket_proposal].freeze
  STATES = %w[prepared running completed failed cancelled timed_out uncertain].freeze
  TERMINAL_STATES = %w[completed failed cancelled timed_out].freeze
  IMMUTABLE_FIELDS = %w[project_id operation_key purpose role selection_revision binding_json binding_digest contract_digest workspace_revision_json private_run_ref].freeze
  BINDING_FIELDS = %w[schema_version operation_id purpose role project_ref workspace_ref schema_digest policy_revision selection_revision selection_source profile harness profile_revision protocol_revision requested_provider requested_model capabilities].freeze
  OPTIONAL_BINDING_FIELDS = %w[thinking model_config_revision revision executable_identity containment_policy_revision].freeze

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

  def binding_valid?
    value = binding
    return false unless value.is_a?(Hash) && (BINDING_FIELDS - value.keys).empty? &&
      (value.keys - BINDING_FIELDS - OPTIONAL_BINDING_FIELDS).empty? &&
      value["schema_version"] == "harness-binding/v1" && value["operation_id"] == operation_key &&
      value["purpose"] == purpose && value["role"] == role && value["project_ref"] == project_id.to_s &&
      value["selection_revision"] == selection_revision && %w[codex pi direct_api].include?(value["harness"]) &&
      (value["harness"] != "direct_api" || role == "ticket_proposal") &&
      %w[workspace_ref schema_digest].all? { |key| /\A[0-9a-f]{64}\z/.match?(value[key].to_s) } &&
      %w[policy_revision profile_revision protocol_revision].all? { |key| value[key].is_a?(String) && value[key].bytesize.between?(1, 128) } &&
      %w[requested_provider requested_model thinking].all? { |key| value[key].nil? || (value[key].is_a?(String) && value[key].bytesize.between?(1, 128)) } &&
      value["capabilities"].is_a?(Hash) && value["capabilities"].values.all? { |item| [true, false].include?(item) }
    selection_valid = if value["selection_source"] == "legacy_default"
      value["profile"].nil?
    else
      value["selection_source"] == "prepared_profile" && %w[codex pi].include?(value["harness"]) &&
        value["profile"].is_a?(String) && ProjectHarnessSetting::PROFILE_KEY.match?(value["profile"])
    end
    selection_valid && binding_json.bytesize <= 16 * 1024 && Digest::SHA256.hexdigest(binding_json) == binding_digest
  rescue JSON::ParserError, TypeError
    false
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
    workspace = JSON.parse(workspace_revision_json)
    history = attempts
    valid = binding_valid? &&
      workspace.is_a?(Hash) && workspace_revision_json.bytesize <= 16 * 1024 &&
      history.is_a?(Array) && history.size <= (role == "ticket_proposal" ? 3 : 1) &&
      history.each_with_index.all? { |item, index| item.is_a?(Hash) && item["number"] == index + 1 &&
        /\A[0-9a-f]{64}\z/.match?(item["owner_digest"].to_s) &&
        (STATES - ["prepared"]).include?(item["state"]) && item["started_at"].is_a?(String) && Time.iso8601(item["started_at"]) } &&
      attempts_json.bytesize <= 64 * 1024 &&
      (purpose == "ticket_proposal") == (role == "ticket_proposal") && operation_key.to_s.bytesize.between?(1, 128)
    errors.add(:base, "invalid retained harness data") unless valid
  rescue JSON::ParserError, TypeError, ArgumentError
    errors.add(:base, "invalid retained harness JSON")
  end
end
