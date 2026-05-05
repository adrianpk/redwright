module QuizLoops
  class Runtime
    CONTROLS = %w[skip done cancel].freeze

    Result = Struct.new(
      :ok,
      :status,
      :quiz,
      :entry,
      :question,
      :tags,
      :prompt_intent,
      :fallback_reason,
      :errors,
      keyword_init: true
    ) do
      def ok?
        ok == true
      end
    end

    def initialize(project:, use_case_name: nil, question_provider: QuestionProvider.new, configuration: Configuration.current)
      @project = project
      @use_case_name = use_case_name
      @question_provider = question_provider
      @configuration = configuration
    end

    def open
      quiz = resolve_quiz!
      next_question_result(quiz)
    end

    def advance!(question:, answer:, tags: [])
      quiz = resolve_quiz!
      control = control_from(answer)
      return skipped_result(quiz: quiz, question: question, tags: tags) if control == "skip"
      return terminal_result(status: "done", quiz: quiz) if control == "done"
      return terminal_result(status: "cancelled", quiz: quiz) if control == "cancel"

      entry = quiz.entries.create!(
        question: question,
        answer: answer.to_s.strip,
        status: "answered"
      )
      entry.tag_with!(tags)
      next_question_result(quiz, entry: entry)
    end

    private

    attr_reader :project, :use_case_name, :question_provider, :configuration

    def resolve_quiz!
      return project.find_or_create_main_quiz! if use_case_name.to_s.strip.empty?

      use_case = project.use_cases.find_or_create_by!(slug: use_case_slug) do |record|
        record.name = use_case_name.to_s.strip
      end
      use_case.find_or_create_quiz!
    end

    def use_case_slug
      use_case_name.to_s.strip.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    end

    def skipped_result(quiz:, question:, tags:)
      entry = quiz.entries.create!(
        question: question,
        answer: "",
        status: "skipped"
      )
      entry.tag_with!(tags)
      next_question_result(quiz, entry: entry)
    end

    def next_question_result(quiz, entry: nil)
      return terminal_result(status: "done", quiz: quiz) if quiz.entries.count >= configuration.max_questions

      generated = question_provider.generate(input: input_for(quiz))
      Result.new(
        ok: true,
        status: "collecting",
        quiz: quiz,
        entry: entry,
        question: generated.question,
        tags: generated.tags,
        prompt_intent: generated.prompt_intent,
        fallback_reason: generated.fallback_reason,
        errors: generated.errors
      )
    end

    def terminal_result(status:, quiz:)
      Result.new(
        ok: true,
        status: status,
        quiz: quiz,
        entry: nil,
        question: nil,
        tags: [],
        prompt_intent: {},
        fallback_reason: "",
        errors: []
      )
    end

    def input_for(quiz)
      {
        "project" => {
          "id" => project.id,
          "name" => project.name,
          "description" => project.description,
          "stack_slug" => project.stack_slug
        },
        "quiz" => {
          "id" => quiz.id,
          "use_case_id" => quiz.use_case_id,
          "entry_count" => quiz.entries.count
        },
        "recent_entries" => quiz.entries.order(created_at: :desc).limit(5).reverse.map do |entry|
          {
            "question" => entry.question,
            "answer" => entry.answer,
            "status" => entry.status,
            "tags" => entry.tags.map(&:name)
          }
        end
      }
    end

    def control_from(answer)
      normalized = answer.to_s.strip.downcase
      CONTROLS.include?(normalized) ? normalized : nil
    end
  end
end
