class CreateProjectProtocolDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :project_protocol_documents do |t|
      t.references :project_protocol, null: false, foreign_key: true
      t.string :key, null: false
      t.string :path, null: false
      t.string :title, null: false
      t.string :layer, null: false
      t.integer :position, null: false, default: 0
      t.text :body, null: false
      t.text :provenance_json, null: false, default: "{}"

      t.timestamps
    end

    add_index :project_protocol_documents, [:project_protocol_id, :key], unique: true, name: "idx_project_protocol_documents_unique_key"
    add_index :project_protocol_documents, [:project_protocol_id, :path], unique: true, name: "idx_project_protocol_documents_unique_path"
    add_index :project_protocol_documents, [:project_protocol_id, :position], name: "idx_project_protocol_documents_position"
    add_index :project_protocol_documents, :layer
  end
end
