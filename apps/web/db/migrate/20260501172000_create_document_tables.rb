class CreateDocumentTables < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.references :project, null: false, foreign_key: true
      t.string :artifact_type, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.integer :source_draft_id
      t.boolean :editable, null: false, default: true

      t.timestamps
    end
    add_index :documents, :artifact_type
    add_index :documents, :source_draft_id
    add_foreign_key :documents, :documents, column: :source_draft_id

    create_table :document_relations do |t|
      t.references :from_artifact, null: false, foreign_key: { to_table: :documents }
      t.references :to_artifact, null: false, foreign_key: { to_table: :documents }
      t.string :relation_type, null: false

      t.timestamps
    end
    add_index :document_relations, [ :from_artifact_id, :to_artifact_id, :relation_type ],
              unique: true,
              name: "idx_document_relations_unique_edge"

    create_table :ticket_document_links do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :document, null: false, foreign_key: true
      t.string :role, null: false, default: "reference"

      t.timestamps
    end
    add_index :ticket_document_links, [ :ticket_id, :document_id ],
              unique: true,
              name: "idx_ticket_document_links_unique_ticket_document"
  end
end
