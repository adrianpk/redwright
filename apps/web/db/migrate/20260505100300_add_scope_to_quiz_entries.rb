class AddScopeToQuizEntries < ActiveRecord::Migration[8.1]
  def change
    add_reference :quiz_entries, :project, null: false, foreign_key: true
    add_reference :quiz_entries, :use_case, foreign_key: true

    add_index :quiz_entries, [:project_id, :use_case_id, :created_at], name: "idx_quiz_entries_project_use_case_created"
    add_index :quiz_entries, [:project_id, :status], name: "idx_quiz_entries_project_status"
  end
end
