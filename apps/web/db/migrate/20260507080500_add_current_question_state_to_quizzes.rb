class AddCurrentQuestionStateToQuizzes < ActiveRecord::Migration[8.1]
  def change
    add_column :quizzes, :current_question, :text
    add_column :quizzes, :current_tags_json, :text, null: false, default: "[]"
    add_column :quizzes, :current_prompt_intent_json, :text, null: false, default: "{}"
    add_column :quizzes, :current_fallback_reason, :string, null: false, default: ""
    add_column :quizzes, :current_question_errors_json, :text, null: false, default: "[]"
    add_column :quizzes, :current_question_started_at, :datetime
  end
end
