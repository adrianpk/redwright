class Ticket < ApplicationRecord
  WORKFLOW_STATUSES = %w[open ready in_progress reviewing blocked solved closed].freeze
  WORKFLOW_KINDS = %w[unclassified bug task cleanup follow_up research decision].freeze
  WORKFLOW_SEVERITIES = %w[unclassified low medium high critical].freeze
  WORKFLOW_SCOPES = %w[unclassified ops web runtime llm project_setup docs infra].freeze
  WORKFLOW_SOURCES = %w[chat manual_test review trace user_report implementation].freeze
  WORKFLOW_RESOLUTIONS = %w[fixed wont_do duplicate obsolete moved answered].freeze
  COLUMN_STATUS_MAP = {
    "backlog" => "ready",
    "open" => "open",
    "ready" => "ready",
    "in_progress" => "in_progress",
    "review" => "reviewing",
    "reviewing" => "reviewing",
    "approved" => "reviewing",
    "blocked" => "blocked",
    "merged" => "solved",
    "done" => "solved",
    "solved" => "solved",
    "closed" => "closed"
  }.freeze
  RUNTIME_EXECUTION_STATUSES = %w[started failed].freeze

  belongs_to :board
  belongs_to :column
  belongs_to :use_case, optional: true
  has_many :ticket_labels, dependent: :destroy
  has_many :labels, through: :ticket_labels
  has_many :ticket_document_links, dependent: :destroy
  has_many :documents, through: :ticket_document_links
  has_many :ticket_comments, dependent: :destroy
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  serialize :commits, coder: JSON

  enum :priority, { low: 0, medium: 1, high: 2 }, default: :medium

  before_validation :assign_workflow_defaults

  validates :title, presence: true
  validates :workflow_status, inclusion: { in: WORKFLOW_STATUSES }, allow_blank: true
  validates :kind, inclusion: { in: WORKFLOW_KINDS }, allow_blank: true
  validates :severity, inclusion: { in: WORKFLOW_SEVERITIES }, allow_blank: true
  validates :scope, inclusion: { in: WORKFLOW_SCOPES }, allow_blank: true
  validates :source, inclusion: { in: WORKFLOW_SOURCES }, allow_blank: true
  validates :resolution, inclusion: { in: WORKFLOW_RESOLUTIONS }, allow_blank: true
  validates :runtime_execution_status, inclusion: { in: RUNTIME_EXECUTION_STATUSES }, allow_blank: true
  validate :resolution_matches_terminal_status
  validate :use_case_belongs_to_project

  scope :visible_on_board, -> { where(archived_at: nil) }
  scope :ordered_for_board, -> { order(priority: :desc, created_at: :asc) }
  scope :active, -> { visible_on_board.joins(:column).where.not(columns: { key: [ "merged", "done" ] }) }
  scope :for_project, ->(project_id) { joins(:board).where(boards: { project_id: project_id }) }
  scope :for_use_case, ->(use_case_id) { where(use_case_id: use_case_id) }
  scope :with_workflow_status, ->(*statuses) { where(workflow_status: statuses.flatten) }

  delegate :project, :project_id, to: :board

  def transition_to_column!(target_column)
    self.column = target_column
    self.workflow_status = workflow_status_for_column(target_column)
    now = Time.current

    case workflow_status
    when "ready"
      self.ready_at ||= now
    when "in_progress"
      self.started_at ||= now
    when "reviewing"
      self.sent_to_review_at ||= now if target_column.key == "review"
      self.review_started_at ||= now
    when "solved"
      self.merge_started_at ||= now if %w[merged done].include?(target_column.key)
      self.merged_at ||= now if %w[merged done].include?(target_column.key)
      self.closed_at ||= now
    when "closed"
      self.closed_at ||= now
    end

    case target_column.key
    when "in_progress"
      self.started_at ||= now
    when "review"
      self.sent_to_review_at ||= now
      self.review_started_at ||= now
    when "approved"
      self.review_completed_at ||= now
    when "merged", "done"
      self.merge_started_at ||= now
      self.merged_at ||= now
    end

    save!
  end

  def workflow_status_for_column(candidate_column = column)
    self.class.workflow_status_for_column_key(candidate_column&.key)
  end

  def self.workflow_status_for_column_key(column_key)
    COLUMN_STATUS_MAP.fetch(column_key.to_s, "open")
  end

  def review_elapsed_seconds
    return 0 unless review_started_at

    ((review_completed_at || Time.current) - review_started_at).to_i
  end

  def total_elapsed_seconds
    return 0 unless started_at

    ((merged_at || Time.current) - started_at).to_i
  end

  def self.pick_next_for(board:, assignee: nil)
    relation = board.tickets.active
    assigned = assignee.to_s.strip.empty? ? Ticket.none : relation.where(assignee: assignee.to_s.strip)
    pool = assigned.exists? ? assigned : relation
    pool.ordered_for_board.first
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def project_context_consistent?(candidate_project_id)
    candidate_project_id.to_i == project_id
  end

  def tag_with!(*names)
    names.flatten.filter_map do |name|
      next if Tag.normalize_name(name).blank?

      tag = Tag.find_or_create_normalized!(name)
      taggings.find_or_create_by!(tag: tag)
      tag
    end
  end

  def record_runtime_execution!(result)
    update!(
      runtime_execution_id: result.execution_id,
      runtime_execution_status: result.status,
      runtime_project_ref: result.runtime_project_ref,
      runtime_workstream_id: result.runtime_workstream_id,
      runtime_task_id: result.runtime_task_id,
      runtime_state: result.runtime_state,
      runtime_execution_started_at: (Time.current if result.ok?),
      runtime_execution_error: result.ok? ? nil : result.error_message
    )
  end

  def runtime_execution
    {
      "execution_id" => runtime_execution_id,
      "status" => runtime_execution_status,
      "runtime_project_ref" => runtime_project_ref,
      "runtime_workstream_id" => runtime_workstream_id,
      "runtime_task_id" => runtime_task_id,
      "runtime_state" => runtime_state,
      "started_at" => runtime_execution_started_at&.iso8601,
      "error" => runtime_execution_error
    }
  end

  private

  def assign_workflow_defaults
    self.workflow_status = workflow_status_for_column if column
    self.kind = "unclassified" if kind.blank?
    self.severity = "unclassified" if severity.blank?
    self.scope = "unclassified" if scope.blank?
    self.source = "chat" if source.blank?
    self.commits = [] if commits.blank?
    self.ready_at ||= created_at || Time.current if workflow_status == "ready"
    self.closed_at ||= Time.current if workflow_status.in?(%w[solved closed]) && closed_at.blank?
  end

  def resolution_matches_terminal_status
    return if resolution.blank?
    return if workflow_status.in?(%w[solved closed])

    errors.add(:resolution, "can only be set for solved or closed tickets")
  end

  def use_case_belongs_to_project
    return unless use_case
    return if use_case.project_id == project_id

    errors.add(:use_case, "must belong to the same project")
  end
end
