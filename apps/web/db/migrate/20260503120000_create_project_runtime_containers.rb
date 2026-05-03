class CreateProjectRuntimeContainers < ActiveRecord::Migration[8.1]
  def change
    create_table :project_runtime_containers do |t|
      t.references :project, null: false, foreign_key: true, index: { unique: true }
      t.string :profile, null: false, default: "default"
      t.string :status, null: false, default: "draft"
      t.string :readiness, null: false, default: "missing"
      t.string :base_image
      t.string :runtime_name
      t.string :runtime_version
      t.string :working_directory
      t.text :system_packages_json, null: false, default: "[]"
      t.text :dependency_commands_json, null: false, default: "[]"
      t.text :test_commands_json, null: false, default: "[]"
      t.text :lint_commands_json, null: false, default: "[]"
      t.text :build_commands_json, null: false, default: "[]"
      t.text :format_commands_json, null: false, default: "[]"
      t.text :repository_mount_json, null: false, default: "{}"
      t.text :cache_mounts_json, null: false, default: "[]"
      t.text :environment_json, null: false, default: "{}"
      t.text :secret_placeholders_json, null: false, default: "[]"
      t.text :network_policy_json, null: false, default: "{}"
      t.text :user_policy_json, null: false, default: "{}"
      t.text :validation_command
      t.string :validation_status, null: false, default: "not_run"
      t.text :validation_output_summary
      t.text :generated_files_json, null: false, default: "[]"
      t.text :provenance_json, null: false, default: "{}"
      t.text :assumptions_json, null: false, default: "[]"
      t.text :missing_information_json, null: false, default: "[]"
      t.text :risks_json, null: false, default: "[]"

      t.timestamps
    end

    add_index :project_runtime_containers, :readiness
    add_index :project_runtime_containers, :validation_status
  end
end
