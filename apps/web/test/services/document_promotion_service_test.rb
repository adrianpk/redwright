require "test_helper"

class DocumentPromotionServiceTest < ActiveSupport::TestCase
  test "promotes draft and relation atomically" do
    draft = create_document(artifact_type: "draft", title: "Draft", body: "Draft body")

    spec = DocumentPromotionService.new(draft: draft).call

    assert_equal "spec", spec.artifact_type
    assert_equal draft.id, spec.source_draft_id
    assert_equal false, spec.editable
    relation = DocumentRelation.find_by(from_artifact: spec, to_artifact: draft)
    assert_equal "derives_from", relation.relation_type
  end

  test "promoted spec preserves draft use case scope" do
    project = create_project(key: "promotion-use-case-scope")
    use_case = create_use_case(project: project, name: "Billing")
    draft = create_document(project: project, use_case: use_case, artifact_type: "draft", title: "Billing Draft", body: "Draft body")

    spec = DocumentPromotionService.new(draft: draft).call

    assert_equal use_case.id, spec.use_case_id
  end

  test "raises explicit promotion error for non-drafts" do
    plan = create_document(artifact_type: "plan_tracker", title: "Plan", body: "Plan body", editable: false)

    error = assert_raises(DocumentPromotionService::PromotionError) do
      DocumentPromotionService.new(draft: plan).call
    end

    assert_equal "artifact is not a draft", error.message
  end
end
