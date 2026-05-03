class CreateProjectProtocolTemplateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :project_protocol_template_documents do |t|
      t.references :project_protocol_template, null: false, foreign_key: true
      t.string :key, null: false
      t.string :path, null: false
      t.string :title, null: false
      t.string :layer, null: false
      t.integer :position, null: false, default: 0
      t.text :body, null: false

      t.timestamps
    end

    add_index :project_protocol_template_documents, [:project_protocol_template_id, :key], unique: true, name: "idx_project_protocol_template_docs_key"
    add_index :project_protocol_template_documents, [:project_protocol_template_id, :path], unique: true, name: "idx_project_protocol_template_docs_path"
    add_index :project_protocol_template_documents, [:project_protocol_template_id, :position], name: "idx_project_protocol_template_docs_position"
  end
end
