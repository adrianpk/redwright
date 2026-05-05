module QuizContext
  class RetrievalQuery
    Result = Struct.new(:quiz_entries, :tickets, :taggings, keyword_init: true)

    def initialize(project:, use_case: nil, tags: [])
      @project = project
      @use_case = use_case
      @tags = Array(tags)
    end

    def call
      scoped_taggings = taggings_scope
      Result.new(
        quiz_entries: quiz_entries_for(scoped_taggings),
        tickets: tickets_for(scoped_taggings),
        taggings: scoped_taggings
      )
    end

    private

    attr_reader :project, :use_case, :tags

    def taggings_scope
      scope = Tagging.includes(:tag).for_project(project)
      scope = scope.for_use_case(use_case) if use_case
      scope = scope.with_tag_names(tags) if normalized_tags.any?
      scope
    end

    def quiz_entries_for(scoped_taggings)
      ids = scoped_taggings.where(taggable_type: "QuizEntry").pluck(:taggable_id)
      QuizEntry.where(id: ids).order(created_at: :desc, id: :desc)
    end

    def tickets_for(scoped_taggings)
      ids = scoped_taggings.where(taggable_type: "Ticket").pluck(:taggable_id)
      Ticket.where(id: ids).order(created_at: :desc, id: :desc)
    end

    def normalized_tags
      @normalized_tags ||= tags.map { |tag| Tag.normalize_name(tag) }.reject(&:blank?)
    end
  end
end
