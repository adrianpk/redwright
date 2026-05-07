class DocumentPromotionService
  PromotionError = Class.new(StandardError)

  def initialize(draft:)
    @draft = draft
  end

  def call
    raise PromotionError, "artifact is not a draft" unless @draft.artifact_type == "draft"

    Document.transaction do
      spec = Document.create!(
        artifact_type: "spec",
        title: @draft.title,
        body: @draft.body,
        project: @draft.project,
        source_draft: @draft,
        editable: false
      )

      DocumentRelation.create!(
        from_artifact: spec,
        to_artifact: @draft,
        relation_type: "derives_from"
      )

      spec
    end
  rescue ActiveRecord::RecordInvalid => e
    raise PromotionError, e.record.errors.full_messages.to_sentence
  end
end
