class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.references :board, null: false, foreign_key: true
      t.references :column, null: false, foreign_key: true
      t.string :title, null: false
      t.string :relative_path, null: false
      t.string :source_hash, null: false
      t.datetime :source_modified_at, null: false
      t.string :specification_path
      t.string :tracker_path
      t.string :specification_revision
      t.integer :priority, null: false, default: 1
      t.string :assignee
      t.string :pull_request_url
      t.datetime :started_at
      t.datetime :paused_at
      t.datetime :sent_to_review_at
      t.datetime :review_started_at
      t.datetime :review_completed_at
      t.datetime :merge_started_at
      t.datetime :merged_at

      t.timestamps
    end

    add_index :tickets, [ :board_id, :priority ]
    add_index :tickets, [ :column_id, :created_at ]
    add_index :tickets, [:board_id, :relative_path], unique: true
    add_index :tickets, :specification_path
  end
end
