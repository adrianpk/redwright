module DumpContext
  class RetrievalQuery
    Result = Struct.new(:dumps, :taggings, keyword_init: true)

    def initialize(project:, use_case: nil, tags: [], limit: 20)
      @project = project
      @use_case = use_case
      @tags = Array(tags)
      @limit = limit.to_i.positive? ? limit.to_i : 20
    end

    def call
      scoped_taggings = taggings_scope
      Result.new(
        dumps: dumps_for(scoped_taggings),
        taggings: scoped_taggings
      )
    end

    private

    attr_reader :project, :use_case, :tags, :limit

    def taggings_scope
      scope = Tagging.includes(:tag).for_project(project).where(taggable_type: "Dump")
      scope = scope.for_use_case(use_case) if use_case
      scope = scope.with_tag_names(tags) if normalized_tags.any?
      scope
    end

    def dumps_for(scoped_taggings)
      ids = scoped_taggings.pluck(:taggable_id)
      scope = project.dumps.curated.includes(:use_case, :tags)
      scope = scope.for_use_case(use_case.id) if use_case
      scope = scope.where(id: ids) if normalized_tags.any?
      scope.order(updated_at: :desc, created_at: :desc).limit(limit)
    end

    def normalized_tags
      @normalized_tags ||= tags.map { |tag| Tag.normalize_name(tag) }.reject(&:blank?)
    end
  end
end
