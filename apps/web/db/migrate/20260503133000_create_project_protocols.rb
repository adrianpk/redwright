class CreateProjectProtocols < ActiveRecord::Migration[8.1]
  def change
    create_table :project_protocols do |t|
      t.references :project, null: false, foreign_key: true, index: {unique: true}
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    add_index :project_protocols, :status
  end
end
