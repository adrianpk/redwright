class CreateDumps < ActiveRecord::Migration[8.1]
  def change
    create_table :dumps do |t|
      t.references :project, null: false, foreign_key: true
      t.references :use_case, foreign_key: true
      t.string :title, null: false
      t.string :slug, null: false
      t.string :status, null: false, default: "active"
      t.string :capture_status, null: false, default: "capturing"
      t.string :curation_status, null: false, default: "not_curated"
      t.text :raw_body, null: false, default: ""
      t.text :curated_body, null: false, default: ""
      t.text :summary, null: false, default: ""

      t.timestamps
    end

    add_index :dumps, [:project_id, :slug], unique: true
    add_index :dumps, [:project_id, :use_case_id, :created_at], name: "idx_dumps_project_use_case_created"
    add_index :dumps, [:project_id, :status], name: "idx_dumps_project_status"
    add_index :dumps, :capture_status
    add_index :dumps, :curation_status
  end
end
