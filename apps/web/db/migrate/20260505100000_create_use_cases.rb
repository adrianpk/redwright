class CreateUseCases < ActiveRecord::Migration[8.1]
  def change
    create_table :use_cases do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end

    add_index :use_cases, [:project_id, :slug], unique: true
  end
end
