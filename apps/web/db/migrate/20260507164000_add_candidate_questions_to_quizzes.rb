class AddCandidateQuestionsToQuizzes < ActiveRecord::Migration[8.0]
  def change
    add_column :quizzes, :candidate_questions_json, :text, null: false, default: "[]"
  end
end
