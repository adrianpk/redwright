class HardenUseCaseDomainForManagementUi < ActiveRecord::Migration[8.1]
  def change
    add_column :use_cases, :description, :text, null: false, default: ""
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE use_cases
          SET description = 'Managed project use case.'
          WHERE description = ''
        SQL
      end
    end
    change_column_default :use_cases, :description, from: "", to: nil
    add_index :use_cases, [ :project_id, :name ], unique: true

    add_reference :documents, :use_case, foreign_key: true
    add_index :documents, [ :project_id, :use_case_id ]
  end
end
