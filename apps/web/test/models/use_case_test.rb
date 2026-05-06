require "test_helper"

class UseCaseTest < ActiveSupport::TestCase
  test "normalizes slug from name within project" do
    project = create_project(key: "use-case-slug")
    use_case = create_use_case(project: project, name: "Billing Flow")

    assert_equal "billing-flow", use_case.slug
  end

  test "requires description" do
    project = create_project(key: "use-case-description")
    use_case = project.use_cases.new(name: "Billing Flow")

    assert_not use_case.valid?
    assert_includes use_case.errors[:description], "can't be blank"
  end

  test "enforces unique name per project" do
    project = create_project(key: "use-case-name-unique")
    create_use_case(project: project, name: "Billing")
    duplicate = project.use_cases.new(name: "Billing", description: "Duplicate")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "enforces unique slug per project" do
    project = create_project(key: "use-case-unique")
    create_use_case(project: project, name: "Billing")
    duplicate = project.use_cases.new(name: "Billing", description: "Duplicate")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "regenerates slug when name changes" do
    use_case = create_use_case(name: "Billing")

    use_case.update!(name: "Invoice Flow")

    assert_equal "invoice-flow", use_case.slug
  end

  test "uses slug as route param" do
    use_case = create_use_case(name: "Billing Flow")

    assert_equal "billing-flow", use_case.to_param
  end

  test "allows same slug in different projects" do
    project = create_project(key: "use-case-project-a")
    other_project = create_project(key: "use-case-project-b")

    create_use_case(project: project, name: "Billing")
    other_use_case = other_project.use_cases.new(name: "Billing", description: "Billing description")

    assert other_use_case.valid?
  end

  test "blocks deletion when referenced by tickets documents quiz entries or taggings" do
    project = create_project(key: "use-case-delete-blocked")
    board = create_board(project: project, project_key: "use-case-delete-blocked")
    backlog = board.columns.create!(key: "backlog", title: "Backlog", position: 0)
    use_case = create_use_case(project: project, name: "Billing")
    board.tickets.create!(column: backlog, title: "Scoped ticket", use_case: use_case)
    create_document(project: project, use_case: use_case)
    quiz = use_case.find_or_create_quiz!
    entry = quiz.entries.create!(question: "What matters?", answer: "Context.")
    entry.tag_with!("Billing")

    assert use_case.deletion_blocked?
    assert_equal 1, use_case.blocking_reference_counts.fetch("tickets")
    assert_equal 1, use_case.blocking_reference_counts.fetch("documents")
    assert_equal 1, use_case.blocking_reference_counts.fetch("quiz")
    assert_equal 1, use_case.blocking_reference_counts.fetch("quiz_entries")
    assert_equal 1, use_case.blocking_reference_counts.fetch("taggings")
    assert_not use_case.destroy
  end

  test "allows deletion when no references exist" do
    use_case = create_use_case(name: "Unreferenced")

    assert_not use_case.deletion_blocked?
    assert_difference("UseCase.count", -1) do
      use_case.destroy!
    end
  end
end
