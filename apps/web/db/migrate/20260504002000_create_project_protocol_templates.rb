class CreateProjectProtocolTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :project_protocol_templates do |t|
      t.string :template_kind, null: false
      t.string :key, null: false
      t.string :name, null: false
      t.text :matchers_json, null: false, default: "[]"
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :project_protocol_templates, [:template_kind, :key], unique: true, name: "idx_project_protocol_templates_kind_key"
    add_index :project_protocol_templates, :status
  end
end
