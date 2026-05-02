class CreateProjectSetupSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :project_setup_sessions do |t|
      t.references :project, null: true, foreign_key: true
      t.string :source_channel, null: false, default: "web"
      t.string :actor_identifier, null: false
      t.string :request_id, null: false
      t.string :status, null: false, default: "open"
      t.string :current_state, null: false, default: "collecting_context"
      t.string :repository_input
      t.text :resolved_repository_json, null: false, default: "{}"
      t.text :pending_question
      t.integer :turn_counter, null: false, default: 0
      t.string :terminal_reason
      t.text :metadata_json, null: false, default: "{}"

      t.timestamps
    end

    add_index :project_setup_sessions, [ :status, :updated_at ]
    add_index :project_setup_sessions, :current_state
    add_index :project_setup_sessions, :request_id

    create_table :project_setup_turns do |t|
      t.references :project_setup_session, null: false, foreign_key: true
      t.integer :turn_index, null: false
      t.string :source_channel, null: false
      t.string :request_id
      t.text :question, null: false
      t.text :answer, null: false
      t.text :normalized_fields_json, null: false, default: "{}"

      t.timestamps
    end

    add_index :project_setup_turns,
              [ :project_setup_session_id, :turn_index ],
              unique: true,
              name: "idx_project_setup_turns_unique_session_turn"
  end
end
