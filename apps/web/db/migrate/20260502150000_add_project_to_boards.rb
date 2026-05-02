class AddProjectToBoards < ActiveRecord::Migration[8.1]
  def up
    return if column_exists?(:boards, :project_id)

    add_reference :boards, :project, null: false, foreign_key: true
  end

  def down
    return unless column_exists?(:boards, :project_id)

    remove_reference :boards, :project, foreign_key: true
  end
end
