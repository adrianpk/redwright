class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.string :root_path, null: false
      t.string :repo_url, null: false
      t.string :stack_slug, null: false

      t.timestamps
    end

    add_index :projects, :root_path, unique: true
    add_index :projects, :repo_url, unique: true
  end
end
