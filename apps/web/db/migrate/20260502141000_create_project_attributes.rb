class CreateProjectAttributes < ActiveRecord::Migration[8.1]
  def change
    create_table :project_attributes do |t|
      t.references :project, null: false, foreign_key: true
      t.string :key, null: false
      t.text :value, null: false
      t.integer :weight, null: false
      t.string :source, null: false

      t.timestamps
    end

    add_index :project_attributes, [:project_id, :key]
    add_index :project_attributes, [:project_id, :weight]
  end
end
