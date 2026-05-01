class DocumentArtifactPromotionService
  def initialize(draft:)
    @draft = draft
  end

  def call
    raise ArgumentError, "artifact is not a draft" unless @draft.artifact_type == "draft"

    spec = DocumentArtifact.create!(
      artifact_type: "spec",
      title: @draft.title,
      body: @draft.body,
      source_draft: @draft,
      editable: false
    )

    DocumentArtifactRelation.create!(
      from_artifact: spec,
      to_artifact: @draft,
      relation_type: "derives_from"
    )

    spec
  end
end
