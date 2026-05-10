require "test_helper"

class DumpTest < ActiveSupport::TestCase
  test "creates project level dump with lifecycle defaults" do
    project = create_project(key: "dump-project-level")

    dump = project.dumps.create!(title: "Architecture Notes")

    assert_equal project.id, dump.project_id
    assert_nil dump.use_case_id
    assert_equal "architecture-notes", dump.slug
    assert_equal "active", dump.status
    assert_equal "capturing", dump.capture_status
    assert_equal "not_curated", dump.curation_status
    assert dump.capturing?
    assert_not dump.curated?
  end

  test "creates use case scoped dump" do
    project = create_project(key: "dump-use-case")
    use_case = create_use_case(project: project, name: "Billing")

    dump = project.dumps.create!(use_case: use_case, title: "Billing Rules")

    assert_equal project.id, dump.project_id
    assert_equal use_case.id, dump.use_case_id
    assert_equal [dump.id], project.dumps.for_use_case(use_case.id).pluck(:id)
  end

  test "rejects use case from another project" do
    project = create_project(key: "dump-project-owner")
    other_project = create_project(key: "dump-other-owner")
    other_use_case = create_use_case(project: other_project, name: "External")
    dump = project.dumps.new(use_case: other_use_case, title: "Invalid Dump")

    assert_not dump.valid?
    assert_includes dump.errors[:use_case], "must belong to the same project"
  end

  test "generates title and slug for unnamed dump" do
    project = create_project(key: "dump-unnamed")

    dump = project.dumps.create!

    assert_match(/\AUntitled Dump [a-f0-9]{8}\z/, dump.title)
    assert_match(/\Auntitled-dump-[a-f0-9]{8}\z/, dump.slug)
  end

  test "enforces project local slug uniqueness" do
    project = create_project(key: "dump-slug-unique")
    other_project = create_project(key: "dump-slug-other")
    project.dumps.create!(title: "Shared Notes")
    duplicate = project.dumps.new(title: "Shared Notes")
    other_dump = other_project.dumps.new(title: "Shared Notes")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
    assert other_dump.valid?
  end

  test "scopes project level and curated dumps" do
    project = create_project(key: "dump-scopes")
    use_case = create_use_case(project: project, name: "Checkout")
    project_dump = project.dumps.create!(title: "Project Dump", curation_status: "curated")
    project.dumps.create!(use_case: use_case, title: "Use Case Dump")

    assert_equal [project_dump.id], project.dumps.project_level.pluck(:id)
    assert_equal [project_dump.id], project.dumps.curated.pluck(:id)
  end
end
