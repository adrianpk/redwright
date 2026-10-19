class CreateHarnessOperations < ActiveRecord::Migration[8.1]
  def change
    create_table :harness_operations do |t|
      t.references :project, null: false, foreign_key: true
      t.string :operation_key, null: false
      t.string :purpose, null: false
      t.string :role, null: false
      t.string :state, null: false, default: "prepared"
      t.integer :selection_revision, null: false
      t.text :binding_json, null: false
      t.string :binding_digest, null: false
      t.string :contract_digest, null: false
      t.text :workspace_revision_json, null: false, default: "{}"
      t.text :attempts_json, null: false, default: "[]"
      t.string :private_run_ref, null: false
      t.datetime :started_at
      t.datetime :finished_at
      t.timestamps
      t.check_constraint "length(CAST(operation_key AS BLOB)) BETWEEN 1 AND 128", name: "harness_operation_key_size"
      t.check_constraint "purpose IN ('specification','slicing','curation','references','ticket_proposal') AND ((role = 'ticket_proposal' AND purpose = 'ticket_proposal') OR (role = 'authoring' AND purpose != 'ticket_proposal'))", name: "harness_operation_purpose_role"
      t.check_constraint "state IN ('prepared','running','completed','failed','cancelled','timed_out','uncertain')", name: "harness_operation_state"
      t.check_constraint "selection_revision >= 0", name: "harness_operation_revision"
      t.check_constraint "json_valid(binding_json) AND json_type(binding_json) = 'object' AND length(CAST(binding_json AS BLOB)) <= 16384", name: "harness_operation_binding"
      t.check_constraint "json_valid(workspace_revision_json) AND json_type(workspace_revision_json) = 'object' AND length(CAST(workspace_revision_json AS BLOB)) <= 16384", name: "harness_operation_workspace"
      t.check_constraint "json_valid(attempts_json) AND json_type(attempts_json) = 'array' AND json_array_length(attempts_json) <= CASE WHEN role = 'ticket_proposal' THEN 3 ELSE 1 END AND length(CAST(attempts_json AS BLOB)) <= 65536", name: "harness_operation_attempts"
      t.check_constraint "length(binding_digest) = 64 AND length(contract_digest) = 64 AND length(private_run_ref) = 36", name: "harness_operation_identity"
    end
    add_index :harness_operations, [:project_id, :operation_key], unique: true
    add_index :harness_operations, [:project_id, :state, :created_at], name: "idx_harness_operations_admission"
  end
end
