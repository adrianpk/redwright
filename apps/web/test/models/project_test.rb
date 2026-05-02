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

  test "project scoped helpers return only project-owned records" do
    project = create_project(key: "project-scope-a")
    other_project = create_project(key: "project-scope-b")
    board = create_board(project_key: "scope-a-board", project: project)
    other_board = create_board(project_key: "scope-b-board", project: other_project)
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    other_backlog = other_board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    ticket = board.tickets.create!(column: backlog, title: "Scoped ticket")
    other_board.tickets.create!(column: other_backlog, title: "Other ticket")
    project_attr = ProjectAttribute.create!(project: project, key: "lang", value: "ruby", weight: 5, source: "user")
    ProjectAttribute.create!(project: other_project, key: "lang", value: "go", weight: 5, source: "user")
    artifact = create_document_artifact(project: project, title: "Scoped artifact")
    create_document_artifact(project: other_project, title: "Other artifact")

    assert_equal [board.id], project.boards_scope.pluck(:id)
    assert_equal [ticket.id], project.tickets_scope.pluck(:id)
    assert_equal [artifact.id], project.document_artifacts_scope.pluck(:id)
    assert_equal [project_attr.id], project.project_attributes_scope.pluck(:id)
  end
end
