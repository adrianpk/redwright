class AddProjectToDocuments < ActiveRecord::Migration[8.1]
  def up
    return if column_exists?(:documents, :project_id)

    add_reference :documents, :project, null: false, foreign_key: true
  end

  def down
    return unless column_exists?(:documents, :project_id)

    remove_reference :documents, :project, foreign_key: true
  end
end
