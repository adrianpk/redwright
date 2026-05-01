require "test_helper"

class DocumentArtifactsControllerTest < ActionDispatch::IntegrationTest
  def create_admin_user!
    User.create!(
      email_address: "docs-owner@example.com",
      password: "password-123",
      password_confirmation: "password-123"
    )
  end

  test "index requires authentication" do
    get document_artifacts_path
    assert_redirected_to new_session_path
  end

  test "create and update draft" do
    admin = create_admin_user!
    sign_in_as(admin)

    post document_artifacts_path, params: {
      document_artifact: {
        title: "Feature Draft",
        body: "Initial draft body"
      }
    }
    created = DocumentArtifact.order(:created_at).last
    assert_redirected_to document_artifact_path(created)
    assert_equal "draft", created.artifact_type
    assert_equal true, created.editable

    patch document_artifact_path(created), params: {
      document_artifact: {
        title: "Feature Draft Updated",
        body: "Updated body"
      }
    }
    assert_redirected_to document_artifact_path(created)
    assert_equal "Feature Draft Updated", created.reload.title
  end

  test "promote draft to spec with lineage and relation" do
    admin = create_admin_user!
    sign_in_as(admin)
    draft = DocumentArtifact.create!(
      artifact_type: "draft",
      title: "Draft for Promotion",
      body: "Draft content"
    )

    post promote_document_artifact_path(draft)

    promoted = DocumentArtifact.order(:created_at).last
    assert_equal "spec", promoted.artifact_type
    assert_equal draft.id, promoted.source_draft_id
    assert_equal false, promoted.editable
    relation = DocumentArtifactRelation.find_by(from_artifact_id: promoted.id, to_artifact_id: draft.id)
    refute_nil relation
    assert_equal "derives_from", relation.relation_type
  end
end
