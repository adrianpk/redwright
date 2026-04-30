class CreateLabels < ActiveRecord::Migration[8.1]
  def change
    create_table :labels do |t|
      t.references :board, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, null: false, default: "#3b82f6"

      t.timestamps
    end

    add_index :labels, [ :board_id, :name ], unique: true
  end
end
