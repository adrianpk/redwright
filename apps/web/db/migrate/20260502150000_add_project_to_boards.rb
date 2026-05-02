class AddProjectToBoards < ActiveRecord::Migration[8.1]
  class MigrationBoard < ApplicationRecord
    self.table_name = "boards"
  end

  class MigrationProject < ApplicationRecord
    self.table_name = "projects"
  end

  def up
    add_reference :boards, :project, null: true, foreign_key: true

    MigrationBoard.reset_column_information
    MigrationProject.reset_column_information

    MigrationBoard.find_each do |board|
      project = MigrationProject.create!(
        name: board.name,
        description: "Legacy board backfill for #{board.project_key}",
        root_path: "/legacy/#{board.project_key}",
        repo_url: "https://legacy.invalid/#{board.project_key}",
        stack_slug: "unknown"
      )

      board.update_columns(project_id: project.id)
    end

    change_column_null :boards, :project_id, false
  end

  def down
    remove_reference :boards, :project, foreign_key: true
  end
end
