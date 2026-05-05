class CreateTaggings < ActiveRecord::Migration[8.1]
  def change
    create_table :taggings do |t|
      t.references :tag, null: false, foreign_key: true
      t.references :taggable, null: false, polymorphic: true
      t.references :project, null: false, foreign_key: true
      t.references :use_case, foreign_key: true

      t.timestamps
    end

    add_index :taggings, [ :tag_id, :taggable_type, :taggable_id ], unique: true
    add_index :taggings, [ :project_id, :use_case_id ]
    add_index :taggings, [ :project_id, :tag_id ]
    add_index :taggings, [ :project_id, :use_case_id, :tag_id ]
  end
end
