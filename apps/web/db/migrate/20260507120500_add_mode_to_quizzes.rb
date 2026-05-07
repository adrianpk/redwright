class AddModeToQuizzes < ActiveRecord::Migration[8.1]
  def change
    add_column :quizzes, :mode, :string, null: false, default: "deep"
    add_index :quizzes, :mode
  end
end
