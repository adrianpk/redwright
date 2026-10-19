require "test_helper"

module DumpContext
  class RetrievalQueryTest < ActiveSupport::TestCase
    test "retrieves available dump documents by project use case and tag" do
      project = create_project(key: "dump-context-retrieval")
      use_case = create_use_case(project: project, name: "Billing")
      dump = project.dumps.create!(
        use_case: use_case,
        title: "Billing Dump",
        status: "ready",
        body: "Billing context."
      )
      other_case = create_use_case(project: project, name: "Other feature")
      uncurated = project.dumps.create!(use_case: other_case, title: "Draft Billing Dump")
      other_project = create_project(key: "dump-context-other")
      other_dump = other_project.dumps.create!(title: "Other Dump", status: "ready", body: "Other.")

      dump.tag_with!("Billing")
      uncurated.tag_with!("Billing")
      other_dump.tag_with!("Billing")

      result = RetrievalQuery.new(project: project, use_case: use_case, tags: ["billing"]).call

      assert_equal [dump], result.dumps.to_a
      assert_equal [dump.id], result.taggings.map(&:taggable_id)
      dump.update!(status: "draft")
      assert_equal [dump.id], RetrievalQuery.new(project: project, use_case: use_case, tags: ["billing"]).call.dumps.pluck(:id)
    end

    test "retrieves available project dumps without tags" do
      project = create_project(key: "dump-context-project")
      curated = project.dumps.create!(title: "Project Dump", status: "ready", body: "Project context.")
      draft = project.dumps.create!(title: "Draft Dump", body: "Still being elaborated.")

      result = RetrievalQuery.new(project: project).call

      assert_equal [curated.id, draft.id].sort, result.dumps.pluck(:id).sort
    end
  end
end
