class CreateDumps < ActiveRecord::Migration[8.1]
  def change
    create_table :dumps do |t|
      t.references :project, null: false, foreign_key: true
      t.references :use_case, foreign_key: true
      t.string :title, null: false
      t.string :slug, null: false
      t.string :status, null: false, default: "draft"
      t.string :relative_path, null: false
      t.string :source_hash, null: false
      t.datetime :source_modified_at

      t.timestamps
    end

    add_index :dumps, [:project_id, :slug], unique: true
    add_index :dumps, [:project_id, :use_case_id, :created_at], name: "idx_dumps_project_use_case_created"
    add_index :dumps, [:project_id, :status], name: "idx_dumps_project_status"
    add_index :dumps, [:project_id, :relative_path], unique: true
    add_index :dumps, :use_case_id, unique: true, where: "use_case_id IS NOT NULL", name: "idx_dumps_one_per_feature"
  end
end
