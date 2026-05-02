class Ticket < ApplicationRecord
  RUNTIME_EXECUTION_STATUSES = %w[started failed].freeze

  belongs_to :board
  belongs_to :column
  has_many :ticket_labels, dependent: :destroy
  has_many :labels, through: :ticket_labels
  has_many :ticket_document_links, dependent: :destroy
  has_many :documents, through: :ticket_document_links

  enum :priority, { low: 0, medium: 1, high: 2 }, default: :medium

  validates :title, presence: true
  validates :runtime_execution_status, inclusion: { in: RUNTIME_EXECUTION_STATUSES }, allow_blank: true

  scope :visible_on_board, -> { where(archived_at: nil) }
  scope :ordered_for_board, -> { order(priority: :desc, created_at: :asc) }
  scope :active, -> { visible_on_board.joins(:column).where.not(columns: { key: [ "merged", "done" ] }) }
  scope :for_project, ->(project_id) { joins(:board).where(boards: { project_id: project_id }) }

  delegate :project, :project_id, to: :board

  def transition_to_column!(target_column)
    self.column = target_column
    now = Time.current

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
end
