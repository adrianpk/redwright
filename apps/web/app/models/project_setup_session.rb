require "json"

class ProjectSetupSession < ApplicationRecord
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

  def terminal?
    TERMINAL_STATES.include?(current_state)
  end

  def next_turn_index
    project_setup_turns.maximum(:turn_index).to_i + 1
  end

  private

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
