class CreateDumpEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :dump_entries do |t|
      t.references :dump, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :use_case, foreign_key: true
      t.integer :position, null: false
      t.text :raw_input, null: false
      t.text :polished_input, null: false, default: ""
      t.string :derived_thread_hint, null: false, default: ""

      t.timestamps
    end

    add_index :dump_entries, [:dump_id, :position], unique: true
    add_index :dump_entries, [:project_id, :use_case_id, :created_at], name: "idx_dump_entries_project_use_case_created"
  end
end
