class CreateTicketComments < ActiveRecord::Migration[8.1]
  def change
    create_table :ticket_comments do |t|
      t.references :ticket, null: false, foreign_key: true
      t.string :author_type, null: false
      t.integer :author_id
      t.string :author_label, null: false
      t.string :author_handle
      t.text :body, null: false

      t.timestamps
    end

    add_index :ticket_comments, [ :ticket_id, :created_at, :id ]
    add_index :ticket_comments, [ :author_type, :author_id ]

    create_table :ticket_comment_mentions do |t|
      t.references :ticket_comment, null: false, foreign_key: true
      t.references :ticket, null: false, foreign_key: true
      t.string :target_type, null: false
      t.integer :target_id
      t.string :handle, null: false
      t.string :display_label

      t.timestamps
    end

    add_index :ticket_comment_mentions, [ :ticket_id, :target_type, :target_id ], name: "idx_ticket_comment_mentions_on_ticket_target"
    add_index :ticket_comment_mentions, [ :ticket_comment_id, :handle ], name: "idx_ticket_comment_mentions_on_comment_handle"
  end
end
