class CreateQuizEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :quiz_entries do |t|
      t.references :quiz, null: false, foreign_key: true
      t.text :question, null: false
      t.text :answer, null: false, default: ""
      t.string :status, null: false, default: "answered"
      t.integer :position

      t.timestamps
    end

    add_index :quiz_entries, [:quiz_id, :created_at]
    add_index :quiz_entries, :status
  end
end
