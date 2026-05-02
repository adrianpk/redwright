class AddProjectToDocumentArtifacts < ActiveRecord::Migration[8.1]
  def up
    return if column_exists?(:document_artifacts, :project_id)

    add_reference :document_artifacts, :project, null: false, foreign_key: true
  end

  def down
    return unless column_exists?(:document_artifacts, :project_id)

    remove_reference :document_artifacts, :project, foreign_key: true
  end
end
