require "test_helper"

class DumpEntryTest < ActiveSupport::TestCase
  test "stores raw and polished input together" do
    project = create_project(key: "dump-entry-basic")
    dump = project.dumps.create!(title: "Context Dump")

    entry = dump.entries.create!(raw_input: "teh thing matters", polished_input: "The thing matters.")

    assert_equal "teh thing matters", entry.raw_input
    assert_equal "The thing matters.", entry.polished_input
    assert_equal 1, entry.position
  end

  test "uses raw input as polished fallback" do
    project = create_project(key: "dump-entry-polished-fallback")
    dump = project.dumps.create!(title: "Fallback Dump")

    entry = dump.entries.create!(raw_input: "Keep this.")

    assert_equal "Keep this.", entry.polished_input
  end

  test "denormalizes project and use case from dump" do
    project = create_project(key: "dump-entry-scope")
    use_case = create_use_case(project: project, name: "Billing")
    dump = project.dumps.create!(use_case: use_case, title: "Billing Dump")

    entry = dump.entries.create!(raw_input: "Invoices are monthly.")

    assert_equal project.id, entry.project_id
    assert_equal use_case.id, entry.use_case_id
  end

  test "project level entries remain project level" do
    project = create_project(key: "dump-entry-project-level")
    dump = project.dumps.create!(title: "Project Dump")

    entry = dump.entries.create!(raw_input: "General project context.")

    assert_equal project.id, entry.project_id
    assert_nil entry.use_case_id
  end

  test "auto increments position within dump" do
    project = create_project(key: "dump-entry-position")
    dump = project.dumps.create!(title: "Position Dump")

    first = dump.entries.create!(raw_input: "First")
    second = dump.entries.create!(raw_input: "Second")

    assert_equal [first.id, second.id], dump.entries.ordered.pluck(:id)
    assert_equal 1, first.position
    assert_equal 2, second.position
  end

  test "rejects project scope mismatch" do
    project = create_project(key: "dump-entry-project")
    other_project = create_project(key: "dump-entry-other-project")
    dump = project.dumps.create!(title: "Project Dump")
    entry = dump.entries.new(project: other_project, raw_input: "Mismatch")

    assert_not entry.valid?
    assert_includes entry.errors[:project], "must match dump project"
  end

  test "rejects use case scope mismatch" do
    project = create_project(key: "dump-entry-use-case")
    use_case = create_use_case(project: project, name: "Billing")
    other_use_case = create_use_case(project: project, name: "Support")
    dump = project.dumps.create!(use_case: use_case, title: "Billing Dump")
    entry = dump.entries.new(use_case: other_use_case, raw_input: "Mismatch")

    assert_not entry.valid?
    assert_includes entry.errors[:use_case], "must match dump use case"
  end
end
