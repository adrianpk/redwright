class AddProjectToDocumentArtifacts < ActiveRecord::Migration[8.1]
  class MigrationProject < ApplicationRecord
    self.table_name = "projects"
  end

  class MigrationDocumentArtifact < ApplicationRecord
    self.table_name = "document_artifacts"
  end

  def up
    add_reference :document_artifacts, :project, null: true, foreign_key: true

    MigrationDocumentArtifact.reset_column_information
    MigrationProject.reset_column_information

    fallback_project = MigrationProject.find_or_create_by!(root_path: "/legacy/document-artifacts") do |project|
      project.name = "Legacy Document Artifacts"
      project.description = "Backfilled ownership for legacy document artifacts"
      project.repo_url = "https://legacy.invalid/document-artifacts"
      project.stack_slug = "unknown"
    end

    MigrationDocumentArtifact.where(project_id: nil).update_all(project_id: fallback_project.id)
    change_column_null :document_artifacts, :project_id, false
  end

  def down
    remove_reference :document_artifacts, :project, foreign_key: true
  end
end
