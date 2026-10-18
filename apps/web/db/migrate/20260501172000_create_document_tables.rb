class CreateDocumentTables < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.references :project, null: false, foreign_key: true
      t.string :artifact_type, null: false
      t.string :title, null: false
      t.string :relative_path, null: false
      t.string :status, null: false, default: "draft"
      t.string :source_hash, null: false
      t.datetime :source_modified_at, null: false

      t.timestamps
    end
    add_index :documents, :artifact_type
    add_index :documents, [:project_id, :relative_path], unique: true
    add_index :documents, [:project_id, :status]

    create_table :document_relations do |t|
      t.references :from_artifact, null: false, foreign_key: { to_table: :documents }
      t.references :to_artifact, null: false, foreign_key: { to_table: :documents }
      t.string :relation_type, null: false

      t.timestamps
    end
    add_index :document_relations, [ :from_artifact_id, :to_artifact_id, :relation_type ],
              unique: true,
              name: "idx_document_relations_unique_edge"

  end
end
