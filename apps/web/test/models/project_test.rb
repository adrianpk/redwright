require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "is valid with required attributes" do
    project = Project.new(
      name: "TaskMaster",
      description: "CLI task manager",
      root_path: "/workspace/Projects/TaskMaster",
      repo_url: "https://codeberg.org/acme/taskmaster",
      stack_slug: "go"
    )

    assert project.valid?
  end

  test "requires all required attributes" do
    project = Project.new

    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"
    assert_includes project.errors[:description], "can't be blank"
    assert_includes project.errors[:root_path], "can't be blank"
    assert_includes project.errors[:repo_url], "can't be blank"
    assert_includes project.errors[:stack_slug], "can't be blank"
  end

  test "enforces unique root_path" do
    Project.create!(
      name: "TaskMaster",
      description: "CLI task manager",
      root_path: "/workspace/Projects/TaskMaster",
      repo_url: "https://codeberg.org/acme/taskmaster",
      stack_slug: "go"
    )

    project = Project.new(
      name: "TaskMaster Copy",
      description: "Another",
      root_path: "/workspace/Projects/TaskMaster",
      repo_url: "https://codeberg.org/acme/taskmaster-copy",
      stack_slug: "go"
    )

    assert_not project.valid?
    assert_includes project.errors[:root_path], "has already been taken"
  end

  test "enforces unique repo_url" do
    Project.create!(
      name: "TaskMaster",
      description: "CLI task manager",
      root_path: "/workspace/Projects/TaskMaster",
      repo_url: "https://codeberg.org/acme/taskmaster",
      stack_slug: "go"
    )

    project = Project.new(
      name: "TaskMaster Copy",
      description: "Another",
      root_path: "/workspace/Projects/TaskMaster-Copy",
      repo_url: "https://codeberg.org/acme/taskmaster",
      stack_slug: "ruby"
    )

    assert_not project.valid?
    assert_includes project.errors[:repo_url], "has already been taken"
  end
end
