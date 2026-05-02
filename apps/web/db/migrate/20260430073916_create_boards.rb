class CreateBoards < ActiveRecord::Migration[8.1]
  def change
    create_table :boards do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :project_key, null: false

      t.timestamps
    end

    add_index :boards, :project_key, unique: true
  end
end
