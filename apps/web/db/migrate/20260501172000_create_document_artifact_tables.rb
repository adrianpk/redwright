class CreateDocumentArtifactTables < ActiveRecord::Migration[8.1]
  def change
    create_table :document_artifacts do |t|
      t.references :project, null: false, foreign_key: true
      t.string :artifact_type, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.integer :source_draft_id
      t.boolean :editable, null: false, default: true

      t.timestamps
    end
    add_index :document_artifacts, :artifact_type
    add_index :document_artifacts, :source_draft_id
    add_foreign_key :document_artifacts, :document_artifacts, column: :source_draft_id

    create_table :document_artifact_relations do |t|
      t.references :from_artifact, null: false, foreign_key: { to_table: :document_artifacts }
      t.references :to_artifact, null: false, foreign_key: { to_table: :document_artifacts }
      t.string :relation_type, null: false

      t.timestamps
    end
    add_index :document_artifact_relations, [ :from_artifact_id, :to_artifact_id, :relation_type ],
              unique: true,
              name: "idx_document_artifact_relations_unique_edge"

    create_table :ticket_artifact_links do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :document_artifact, null: false, foreign_key: true
      t.string :role, null: false, default: "reference"

      t.timestamps
    end
    add_index :ticket_artifact_links, [ :ticket_id, :document_artifact_id ],
              unique: true,
              name: "idx_ticket_artifact_links_unique_ticket_artifact"
  end
end
