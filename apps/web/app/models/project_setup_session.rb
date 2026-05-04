require "json"

class ProjectSetupSession < ApplicationRecord
  SETUP_CONTEXT_KEY = "setup_context".freeze
  SETUP_CONTEXT_VERSION = 1
  SETUP_SLOT_KEYS = %w[
    project_name
    description
    project_type
    language_runtime
    repository
    stack
    framework
    libraries
    patterns
    conventions
    runtime_container_profile
    agent_workflow_mode
  ].freeze
  SETUP_SLOT_REQUIREDNESS = {
    "project_name" => "blocking",
    "description" => "recommended",
    "project_type" => "recommended",
    "language_runtime" => "recommended",
    "repository" => "optional",
    "stack" => "recommended",
    "framework" => "optional",
    "libraries" => "optional",
    "patterns" => "optional",
    "conventions" => "optional",
    "runtime_container_profile" => "optional",
    "agent_workflow_mode" => "optional"
  }.freeze
  SETUP_SLOT_WEIGHTS = {
    "project_name" => 10,
    "description" => 8,
    "project_type" => 7,
    "language_runtime" => 7,
    "repository" => 5,
    "stack" => 6,
    "framework" => 5,
    "libraries" => 4,
    "patterns" => 4,
    "conventions" => 4,
    "runtime_container_profile" => 3,
    "agent_workflow_mode" => 3
  }.freeze
  STATUSES = %w[open completed cancelled failed needs_reconciliation].freeze
  STATES = %w[
    collecting_context
    awaiting_repository
    awaiting_repository_confirmation
    awaiting_alignment_opt_in
    collecting_alignment
    ready_to_create
    creating_project
    completed
    cancelled
    failed
    needs_reconciliation
  ].freeze
  TERMINAL_STATES = %w[completed cancelled failed needs_reconciliation].freeze
  TERMINAL_REASONS = %w[
    completed_without_alignment
    completed_with_alignment
    cancelled_by_user
    failed_reconciled
    failed_needs_reconciliation
  ].freeze

  belongs_to :project, optional: true
  has_many :project_setup_turns, dependent: :destroy

  validates :source_channel, presence: true
  validates :actor_identifier, presence: true
  validates :request_id, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :current_state, inclusion: { in: STATES }
  validates :turn_counter, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :terminal_reason, inclusion: { in: TERMINAL_REASONS }, allow_blank: true
  validate :terminal_state_requires_terminal_reason

  before_validation :set_defaults

  def resolved_repository
    parse_json_object(resolved_repository_json)
  end

  def resolved_repository=(value)
    self.resolved_repository_json = JSON.generate(normalize_hash(value))
  end

  def metadata
    parse_json_object(metadata_json)
  end

  def metadata=(value)
    self.metadata_json = JSON.generate(normalize_hash(value))
  end

  def setup_context
    context = metadata[SETUP_CONTEXT_KEY]
    return default_setup_context unless context.is_a?(Hash)

    default_setup_context.merge(context).tap do |normalized|
      normalized["slots"] = normalize_slots(context["slots"])
    end
  end

  def setup_slots
    setup_context.fetch("slots")
  end

  def setup_slot(key)
    setup_slots[key.to_s]
  end

  def assign_setup_slot(
    key:,
    value:,
    source:,
    raw_value: nil,
    confidence: 1.0,
    requiredness: nil,
    weight: nil,
    status: nil,
    normalization_reason: nil,
    updated_at: Time.current
  )
    slot_key = key.to_s
    raise ArgumentError, "unknown setup slot: #{slot_key}" unless SETUP_SLOT_KEYS.include?(slot_key)

    next_metadata = metadata
    context = setup_context
    context["slots"][slot_key] = build_setup_slot(
      key: slot_key,
      value: value,
      source: source,
      raw_value: raw_value,
      confidence: confidence,
      requiredness: requiredness,
      weight: weight,
      status: status,
      normalization_reason: normalization_reason,
      updated_at: updated_at
    )
    next_metadata[SETUP_CONTEXT_KEY] = context
    self.metadata = next_metadata
  end

  def write_setup_slot!(**kwargs)
    assign_setup_slot(**kwargs)
    save!
  end

  def terminal?
    TERMINAL_STATES.include?(current_state)
  end

  def next_turn_index
    project_setup_turns.maximum(:turn_index).to_i + 1
  end

  def saga_turns
    project_setup_turns.order(:turn_index).map(&:to_saga_turn)
  end

  private

  def default_setup_context
    {
      "version" => SETUP_CONTEXT_VERSION,
      "phase" => "canonical_slot_collection",
      "slots" => {}
    }
  end

  def normalize_slots(value)
    return {} unless value.is_a?(Hash)

    value.each_with_object({}) do |(key, slot), slots|
      slot_key = key.to_s
      next unless SETUP_SLOT_KEYS.include?(slot_key)
      next unless slot.is_a?(Hash)

      slots[slot_key] = stringify_hash(slot).merge("key" => slot_key)
    end
  end

  def build_setup_slot(key:, value:, source:, raw_value:, confidence:, requiredness:, weight:, status:, normalization_reason:, updated_at:)
    cleaned_value = normalize_slot_value(value)
    {
      "key" => key,
      "raw_value" => normalize_slot_value(raw_value.nil? ? value : raw_value),
      "value" => cleaned_value,
      "source" => source.to_s,
      "confidence" => confidence.to_f,
      "weight" => weight || SETUP_SLOT_WEIGHTS.fetch(key),
      "requiredness" => requiredness || SETUP_SLOT_REQUIREDNESS.fetch(key),
      "status" => status || (cleaned_value.to_s.empty? ? "empty" : "filled"),
      "normalization_reason" => normalization_reason.to_s,
      "updated_at" => updated_at.iso8601
    }
  end

  def normalize_slot_value(value)
    return value.map { |item| item.to_s.strip }.reject(&:empty?) if value.is_a?(Array)

    value.to_s.strip
  end

  def stringify_hash(value)
    value.to_h.transform_keys(&:to_s)
  end

  def set_defaults
    self.source_channel = "web" if source_channel.blank?
    self.status = "open" if status.blank?
    self.current_state = "collecting_context" if current_state.blank?
    self.resolved_repository_json = "{}" if resolved_repository_json.blank?
    self.metadata_json = "{}" if metadata_json.blank?
    self.turn_counter = 0 if turn_counter.nil?
  end

  def terminal_state_requires_terminal_reason
    return unless terminal?
    return if terminal_reason.present?

    errors.add(:terminal_reason, "is required for terminal setup states")
  end

  def parse_json_object(raw)
    parsed = JSON.parse(raw.to_s)
    parsed.is_a?(Hash) ? parsed : {}
  rescue JSON::ParserError
    {}
  end

  def normalize_hash(value)
    return {} unless value.is_a?(Hash)

    value.transform_keys(&:to_s)
  end
end
