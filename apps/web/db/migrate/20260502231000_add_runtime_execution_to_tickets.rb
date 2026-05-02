class AddRuntimeExecutionToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :runtime_execution_id, :string
    add_column :tickets, :runtime_execution_status, :string
    add_column :tickets, :runtime_project_ref, :string
    add_column :tickets, :runtime_workstream_id, :string
    add_column :tickets, :runtime_task_id, :string
    add_column :tickets, :runtime_state, :string
    add_column :tickets, :runtime_execution_started_at, :datetime
    add_column :tickets, :runtime_execution_error, :text

    add_index :tickets, :runtime_execution_id
    add_index :tickets, [:runtime_execution_status, :updated_at]
  end
end
