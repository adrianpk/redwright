class AddWorkflowAlignmentToTickets < ActiveRecord::Migration[8.1]
  def up
    add_column :tickets, :workflow_status, :string
    add_column :tickets, :kind, :string
    add_column :tickets, :severity, :string
    add_column :tickets, :scope, :string
    add_column :tickets, :source, :string
    add_column :tickets, :resolution, :string
    add_column :tickets, :owner, :string
    add_column :tickets, :branch, :string
    add_column :tickets, :pr, :string
    add_column :tickets, :commits, :text
    add_column :tickets, :ready_at, :datetime
    add_column :tickets, :reviewed_at, :datetime
    add_column :tickets, :closed_at, :datetime

    add_index :tickets, :workflow_status
    add_index :tickets, [ :board_id, :workflow_status ]
    add_index :tickets, :kind
    add_index :tickets, :severity
    add_index :tickets, :scope

    backfill_workflow_fields
  end

  def down
    remove_index :tickets, :scope
    remove_index :tickets, :severity
    remove_index :tickets, :kind
    remove_index :tickets, [ :board_id, :workflow_status ]
    remove_index :tickets, :workflow_status

    remove_column :tickets, :closed_at
    remove_column :tickets, :reviewed_at
    remove_column :tickets, :ready_at
    remove_column :tickets, :commits
    remove_column :tickets, :pr
    remove_column :tickets, :branch
    remove_column :tickets, :owner
    remove_column :tickets, :resolution
    remove_column :tickets, :source
    remove_column :tickets, :scope
    remove_column :tickets, :severity
    remove_column :tickets, :kind
    remove_column :tickets, :workflow_status
  end

  private

  def backfill_workflow_fields
    execute <<~SQL.squish
      UPDATE tickets
      SET workflow_status = CASE (
          SELECT columns.key FROM columns WHERE columns.id = tickets.column_id
        )
        WHEN 'backlog' THEN 'ready'
        WHEN 'open' THEN 'open'
        WHEN 'ready' THEN 'ready'
        WHEN 'in_progress' THEN 'in_progress'
        WHEN 'review' THEN 'reviewing'
        WHEN 'reviewing' THEN 'reviewing'
        WHEN 'approved' THEN 'reviewing'
        WHEN 'blocked' THEN 'blocked'
        WHEN 'merged' THEN 'solved'
        WHEN 'done' THEN 'solved'
        WHEN 'solved' THEN 'solved'
        WHEN 'closed' THEN 'closed'
        ELSE 'open'
      END,
      kind = 'unclassified',
      severity = 'unclassified',
      scope = 'unclassified',
      source = 'chat',
      commits = '[]'
    SQL

    execute <<~SQL.squish
      UPDATE tickets
      SET ready_at = COALESCE(ready_at, created_at)
      WHERE workflow_status = 'ready'
    SQL

    execute <<~SQL.squish
      UPDATE tickets
      SET closed_at = COALESCE(closed_at, updated_at)
      WHERE workflow_status IN ('solved', 'closed')
    SQL
  end
end
