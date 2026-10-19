module Specifications
  class ContextBuilder
    MAX_CONTEXT_BYTES = 128_000
    MAX_ENTRIES = 100

    def initialize(project:, use_case: nil)
      @project, @use_case = project, use_case
      raise Error, "Use case must belong to the project." if use_case && use_case.project_id != project.id
    end

    def to_h
      value = {
        "project" => @project.attributes.slice("id", "name", "description", "stack_slug"),
        "project_context" => @project.project_attributes.order(weight: :desc, id: :asc).map { |attribute| attribute.attributes.slice("key", "value") },
        "use_case" => @use_case&.attributes&.slice("slug", "name", "description"),
        "dumps" => dumps,
        "quiz_answers" => quiz_answers
      }
      raise Error, "The discovery context is too large. Narrow the selected use case." if value.to_json.bytesize > MAX_CONTEXT_BYTES
      value
    end

    private

    def dumps
      Dump.reconcile!(@project)
      scope = @project.dumps.where(use_case_id: [nil, @use_case&.id].uniq).order(:created_at, :id)
      bounded(scope).map do |dump|
        dump.attributes.slice("id", "title", "status", "relative_path").merge("body" => dump.body)
      end
    end

    def quiz_answers
      quizzes = @project.quizzes.where(use_case_id: [nil, @use_case&.id].uniq).pluck(:id)
      bounded(QuizEntry.where(quiz_id: quizzes, status: "answered").order(:created_at, :id)).map do |entry|
        entry.attributes.slice("id", "quiz_id", "question", "answer")
      end
    end

    def bounded(scope)
      entries = scope.limit(MAX_ENTRIES + 1).to_a
      raise Error, "There are too many discovery entries. Narrow the selected use case." if entries.size > MAX_ENTRIES
      entries
    end
  end
end
