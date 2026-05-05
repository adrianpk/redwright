class CreateQuizzes < ActiveRecord::Migration[8.1]
  def change
    create_table :quizzes do |t|
      t.references :project, null: false, foreign_key: true
      t.references :use_case, foreign_key: true
      t.string :name, null: false
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :quizzes, :status
    add_index :quizzes, [:project_id, :use_case_id], unique: true, where: "use_case_id IS NOT NULL", name: "idx_quizzes_unique_project_use_case"
    add_index :quizzes, :project_id, unique: true, where: "use_case_id IS NULL", name: "idx_quizzes_unique_project_main"
  end
end
