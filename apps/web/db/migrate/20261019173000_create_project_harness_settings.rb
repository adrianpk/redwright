class CreateProjectHarnessSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :project_harness_settings do |t|
      t.references :project, null: false, foreign_key: true, index: {unique: true}
      t.string :authoring_profile
      t.string :ticket_proposal_profile
      t.integer :lock_version, null: false, default: 0
      t.text :mutation_receipts_json, null: false, default: "[]"
      t.references :changed_by, foreign_key: {to_table: :users}
      t.datetime :changed_at
      t.timestamps
      t.check_constraint "authoring_profile IS NULL OR length(CAST(authoring_profile AS BLOB)) BETWEEN 1 AND 128", name: "harness_authoring_profile_size"
      t.check_constraint "ticket_proposal_profile IS NULL OR length(CAST(ticket_proposal_profile AS BLOB)) BETWEEN 1 AND 128", name: "harness_ticket_profile_size"
      t.check_constraint "lock_version >= 0", name: "harness_selection_revision"
      t.check_constraint "json_valid(mutation_receipts_json) AND json_type(mutation_receipts_json) = 'array' AND json_array_length(mutation_receipts_json) <= 128 AND length(CAST(mutation_receipts_json AS BLOB)) <= 131072", name: "harness_selection_receipts"
    end
  end
end
