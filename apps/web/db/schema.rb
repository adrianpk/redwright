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

ActiveRecord::Schema[8.1].define(version: 2026_04_30_120500) do
  create_table "boards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "project_key", null: false
    t.datetime "updated_at", null: false
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

  create_table "labels", force: :cascade do |t|
    t.integer "board_id", null: false
    t.string "color", default: "#3b82f6", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["board_id", "name"], name: "index_labels_on_board_id_and_name", unique: true
    t.index ["board_id"], name: "index_labels_on_board_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
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
    t.datetime "sent_to_review_at"
    t.datetime "started_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["archived_at"], name: "index_tickets_on_archived_at"
    t.index ["board_id", "priority"], name: "index_tickets_on_board_id_and_priority"
    t.index ["board_id"], name: "index_tickets_on_board_id"
    t.index ["column_id", "created_at"], name: "index_tickets_on_column_id_and_created_at"
    t.index ["column_id"], name: "index_tickets_on_column_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "columns", "boards"
  add_foreign_key "labels", "boards"
  add_foreign_key "sessions", "users"
  add_foreign_key "ticket_labels", "labels"
  add_foreign_key "ticket_labels", "tickets"
  add_foreign_key "tickets", "boards"
  add_foreign_key "tickets", "columns"
end
