require "test_helper"

class ProjectHarnessSettingTest < ActiveSupport::TestCase
  test "settings enforce database identity and bounds" do
    # Model validation and direct SQL must both protect this shared authority.
    setting = ProjectHarnessSetting.create!(project: create_project)
    assert_equal 0, setting.public_state.fetch("revision")
    assert_nil setting.authoring_profile
    assert_not_includes setting.as_json.keys, "mutation_receipts_json"
    assert_raises(ActiveRecord::RecordNotUnique) do
      ProjectHarnessSetting.insert_all!([{project_id: setting.project_id}])
    end
    {"oversized profile" => {authoring_profile: "x" * 129},
      "negative revision" => {lock_version: -1},
      "invalid receipts" => {mutation_receipts_json: "{}"},
      "too many receipts" => {mutation_receipts_json: JSON.generate(Array.new(129) { {} })}}.each do |name, attributes|
      setting.reload
      assert_raises(ActiveRecord::StatementInvalid, name) { setting.update_columns(attributes) }
    end
    setting.reload.authoring_profile = "../program"
    assert_not setting.valid?
  end

  test "retained operations protect project deletion" do
    # Technical operation provenance must survive until its references are released.
    project = create_project
    store = Harnesses::BindingStore.new(directory: File.join(project.root_path, "private-bindings"))
    operation = Harnesses::Selection.new(project: project, store: store).admit!(operation_key: "spec-one",
      purpose: "specification", role: "authoring", schema: {}, policy_revision: "v1")
    assert_raises(ActiveRecord::RecordNotDestroyed) { project.destroy! }
    assert HarnessOperation.exists?(operation.id)
    assert_raises(ActiveRecord::StatementInvalid) { operation.update_columns(state: "approved") }
    assert_not_includes operation.as_json.keys, "private_run_ref"
    assert_not_includes operation.as_json.keys, "attempts_json"
  end
end
