require "test_helper"

class UseCaseTest < ActiveSupport::TestCase
  test "normalizes slug from name within project" do
    project = create_project(key: "use-case-slug")
    use_case = project.use_cases.create!(name: "Billing Flow")

    assert_equal "billing-flow", use_case.slug
  end

  test "enforces unique slug per project" do
    project = create_project(key: "use-case-unique")
    project.use_cases.create!(name: "Billing")
    duplicate = project.use_cases.new(name: "Billing")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "allows same slug in different projects" do
    project = create_project(key: "use-case-project-a")
    other_project = create_project(key: "use-case-project-b")

    project.use_cases.create!(name: "Billing")
    other_use_case = other_project.use_cases.new(name: "Billing")

    assert other_use_case.valid?
  end
end
