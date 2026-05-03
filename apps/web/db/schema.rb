# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_03_120000) do
  create_table "boards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "project_id", null: false
    t.string "project_key", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_boards_on_project_id"
    t.index ["project_key"], name: "index_boards_on_project_key", unique: true
  end

  create_table "columns", force: :cascade do |t|
    t.integer "board_id", null: false
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.integer "position", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["board_id", "key"], name: "index_columns_on_board_id_and_key", unique: true
    t.index ["board_id", "position"], name: "index_columns_on_board_id_and_position", unique: true
    t.index ["board_id"], name: "index_columns_on_board_id"
  end

  create_table "document_relations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "from_artifact_id", null: false
    t.string "relation_type", null: false
    t.integer "to_artifact_id", null: false
    t.datetime "updated_at", null: false
    t.index ["from_artifact_id", "to_artifact_id", "relation_type"], name: "idx_document_relations_unique_edge", unique: true
    t.index ["from_artifact_id"], name: "index_document_relations_on_from_artifact_id"
    t.index ["to_artifact_id"], name: "index_document_relations_on_to_artifact_id"
  end

  create_table "documents", force: :cascade do |t|
    t.string "artifact_type", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.boolean "editable", default: true, null: false
    t.integer "project_id", null: false
    t.integer "source_draft_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["artifact_type"], name: "index_documents_on_artifact_type"
    t.index ["project_id"], name: "index_documents_on_project_id"
    t.index ["source_draft_id"], name: "index_documents_on_source_draft_id"
  end

  create_table "labels", force: :cascade do |t|
    t.integer "board_id", null: false
    t.string "color", default: "#3b82f6", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["board_id", "name"], name: "index_labels_on_board_id_and_name", unique: true
    t.index ["board_id"], name: "index_labels_on_board_id"
  end

  create_table "project_attributes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.integer "project_id", null: false
    t.string "source", null: false
    t.datetime "updated_at", null: false
    t.text "value", null: false
    t.integer "weight", null: false
    t.index ["project_id", "key"], name: "index_project_attributes_on_project_id_and_key"
    t.index ["project_id", "weight"], name: "index_project_attributes_on_project_id_and_weight"
    t.index ["project_id"], name: "index_project_attributes_on_project_id"
  end

  create_table "project_runtime_containers", force: :cascade do |t|
    t.text "assumptions_json", default: "[]", null: false
    t.string "base_image"
    t.text "build_commands_json", default: "[]", null: false
    t.text "cache_mounts_json", default: "[]", null: false
    t.datetime "created_at", null: false
    t.text "dependency_commands_json", default: "[]", null: false
    t.text "environment_json", default: "{}", null: false
    t.text "format_commands_json", default: "[]", null: false
    t.text "generated_files_json", default: "[]", null: false
    t.text "lint_commands_json", default: "[]", null: false
    t.text "missing_information_json", default: "[]", null: false
    t.text "network_policy_json", default: "{}", null: false
    t.string "profile", default: "default", null: false
    t.integer "project_id", null: false
    t.text "provenance_json", default: "{}", null: false
    t.string "readiness", default: "missing", null: false
    t.text "repository_mount_json", default: "{}", null: false
    t.text "risks_json", default: "[]", null: false
    t.string "runtime_name"
    t.string "runtime_version"
    t.text "secret_placeholders_json", default: "[]", null: false
    t.string "status", default: "draft", null: false
    t.text "system_packages_json", default: "[]", null: false
    t.text "test_commands_json", default: "[]", null: false
    t.datetime "updated_at", null: false
    t.text "user_policy_json", default: "{}", null: false
    t.text "validation_command"
    t.text "validation_output_summary"
    t.string "validation_status", default: "not_run", null: false
    t.string "working_directory"
    t.index ["project_id"], name: "index_project_runtime_containers_on_project_id", unique: true
    t.index ["readiness"], name: "index_project_runtime_containers_on_readiness"
    t.index ["validation_status"], name: "index_project_runtime_containers_on_validation_status"
  end

  create_table "project_setup_sessions", force: :cascade do |t|
    t.string "actor_identifier", null: false
    t.datetime "created_at", null: false
    t.string "current_state", default: "collecting_context", null: false
    t.text "metadata_json", default: "{}", null: false
    t.text "pending_question"
    t.integer "project_id"
    t.string "repository_input"
    t.string "request_id", null: false
    t.text "resolved_repository_json", default: "{}", null: false
    t.string "source_channel", default: "web", null: false
    t.string "status", default: "open", null: false
    t.string "terminal_reason"
    t.integer "turn_counter", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["current_state"], name: "index_project_setup_sessions_on_current_state"
    t.index ["project_id"], name: "index_project_setup_sessions_on_project_id"
    t.index ["request_id"], name: "index_project_setup_sessions_on_request_id"
    t.index ["status", "updated_at"], name: "index_project_setup_sessions_on_status_and_updated_at"
  end

  create_table "project_setup_turns", force: :cascade do |t|
    t.text "answer", null: false
    t.datetime "created_at", null: false
    t.text "normalized_fields_json", default: "{}", null: false
    t.integer "project_setup_session_id", null: false
    t.text "question", null: false
    t.string "request_id"
    t.string "source_channel", null: false
    t.integer "turn_index", null: false
    t.datetime "updated_at", null: false
    t.index ["project_setup_session_id", "turn_index"], name: "idx_project_setup_turns_unique_session_turn", unique: true
    t.index ["project_setup_session_id"], name: "index_project_setup_turns_on_project_setup_session_id"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "name", null: false
    t.string "repo_url", null: false
    t.string "root_path", null: false
    t.string "stack_slug", null: false
    t.datetime "updated_at", null: false
    t.index ["repo_url"], name: "index_projects_on_repo_url", unique: true
    t.index ["root_path"], name: "index_projects_on_root_path", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "ticket_document_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "document_id", null: false
    t.string "role", default: "reference", null: false
    t.integer "ticket_id", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_ticket_document_links_on_document_id"
    t.index ["ticket_id", "document_id"], name: "idx_ticket_document_links_unique_ticket_artifact", unique: true
    t.index ["ticket_id"], name: "index_ticket_document_links_on_ticket_id"
  end

  create_table "ticket_labels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "label_id", null: false
    t.integer "ticket_id", null: false
    t.datetime "updated_at", null: false
    t.index ["label_id"], name: "index_ticket_labels_on_label_id"
    t.index ["ticket_id", "label_id"], name: "index_ticket_labels_on_ticket_id_and_label_id", unique: true
    t.index ["ticket_id"], name: "index_ticket_labels_on_ticket_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.datetime "archived_at"
    t.string "assignee"
    t.integer "board_id", null: false
    t.integer "column_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "merge_started_at"
    t.datetime "merged_at"
    t.datetime "paused_at"
    t.integer "priority", default: 1, null: false
    t.string "pull_request_url"
    t.datetime "review_completed_at"
    t.datetime "review_started_at"
    t.text "runtime_execution_error"
    t.string "runtime_execution_id"
    t.datetime "runtime_execution_started_at"
    t.string "runtime_execution_status"
    t.string "runtime_project_ref"
    t.string "runtime_state"
    t.string "runtime_task_id"
    t.string "runtime_workstream_id"
    t.datetime "sent_to_review_at"
    t.datetime "started_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["archived_at"], name: "index_tickets_on_archived_at"
    t.index ["board_id", "priority"], name: "index_tickets_on_board_id_and_priority"
    t.index ["board_id"], name: "index_tickets_on_board_id"
    t.index ["column_id", "created_at"], name: "index_tickets_on_column_id_and_created_at"
    t.index ["column_id"], name: "index_tickets_on_column_id"
    t.index ["runtime_execution_id"], name: "index_tickets_on_runtime_execution_id"
    t.index ["runtime_execution_status", "updated_at"], name: "index_tickets_on_runtime_execution_status_and_updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.text "roles_json", default: "[]", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "boards", "projects"
  add_foreign_key "columns", "boards"
  add_foreign_key "document_relations", "documents", column: "from_artifact_id"
  add_foreign_key "document_relations", "documents", column: "to_artifact_id"
  add_foreign_key "documents", "documents", column: "source_draft_id"
  add_foreign_key "documents", "projects"
  add_foreign_key "labels", "boards"
  add_foreign_key "project_attributes", "projects"
  add_foreign_key "project_runtime_containers", "projects"
  add_foreign_key "project_setup_sessions", "projects"
  add_foreign_key "project_setup_turns", "project_setup_sessions"
  add_foreign_key "sessions", "users"
  add_foreign_key "ticket_document_links", "documents"
  add_foreign_key "ticket_document_links", "tickets"
  add_foreign_key "ticket_labels", "labels"
  add_foreign_key "ticket_labels", "tickets"
  add_foreign_key "tickets", "boards"
  add_foreign_key "tickets", "columns"
end
