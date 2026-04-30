class CreateColumns < ActiveRecord::Migration[8.1]
  def change
    create_table :columns do |t|
      t.references :board, null: false, foreign_key: true
      t.string :key, null: false
      t.string :title, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :columns, [ :board_id, :key ], unique: true
    add_index :columns, [ :board_id, :position ], unique: true
  end
end
