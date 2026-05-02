require "test_helper"

class ProjectAttributeTest < ActiveSupport::TestCase
  def build_project
    Project.create!(
      name: "TaskMaster",
      description: "CLI task manager",
      root_path: "/workspace/Projects/TaskMaster",
      repo_url: "https://codeberg.org/acme/taskmaster",
      stack_slug: "go"
    )
  end

  test "is valid with key value weight and source" do
    attribute = ProjectAttribute.new(
      project: build_project,
      key: "language",
      value: "ruby",
      weight: 4,
      source: "user"
    )

    assert attribute.valid?
  end

  test "requires key value weight and source" do
    attribute = ProjectAttribute.new(project: build_project)

    assert_not attribute.valid?
    assert_includes attribute.errors[:key], "can't be blank"
    assert_includes attribute.errors[:value], "can't be blank"
    assert_includes attribute.errors[:weight], "can't be blank"
    assert_includes attribute.errors[:source], "can't be blank"
  end

  test "requires weight between one and five" do
    project = build_project

    low_weight = ProjectAttribute.new(project: project, key: "tone", value: "concise", weight: 0, source: "agent")
    high_weight = ProjectAttribute.new(project: project, key: "tone", value: "concise", weight: 6, source: "agent")

    assert_not low_weight.valid?
    assert_includes low_weight.errors[:weight], "must be greater than or equal to 1"

    assert_not high_weight.valid?
    assert_includes high_weight.errors[:weight], "must be less than or equal to 5"
  end

  test "belongs to project association is required" do
    attribute = ProjectAttribute.new(
      key: "framework",
      value: "rails",
      weight: 3,
      source: "system"
    )

    assert_not attribute.valid?
    assert_includes attribute.errors[:project], "must exist"
  end
end
