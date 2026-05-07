module QuizLoops
  class Runtime
    CONTROLS = %w[skip done cancel].freeze
    TRUNK_RETURN_QUESTION = "What broader project context should this quiz cover next?".freeze

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
      return current_question_result(quiz) if quiz.current_question?

      next_question_result(quiz)
    end

    def advance!(question: nil, answer:, tags: nil)
      quiz = resolve_quiz!
      control = control_from(answer)
      question_for_entry = current_or_submitted_question(quiz: quiz, question: question)
      tags_for_entry = current_or_submitted_tags(quiz: quiz, tags: tags)

      return skipped_result(quiz: quiz, question: question_for_entry, tags: tags_for_entry) if control == "skip"
      return stop_result(status: "done", quiz: quiz) if control == "done"
      return stop_result(status: "cancelled", quiz: quiz) if control == "cancel"

      entry = quiz.entries.create!(
        question: question_for_entry,
        answer: answer.to_s.strip,
        status: "answered"
      )
      entry.tag_with!(tags_for_entry)
      next_question_result(quiz, entry: entry)
    end

    private

    attr_reader :project, :use_case_name, :question_provider, :configuration

    def resolve_quiz!
      return project.find_or_create_main_quiz! if use_case_name.to_s.strip.empty?

      use_case = project.use_cases.find_or_create_by!(slug: use_case_slug) do |record|
        record.name = use_case_name.to_s.strip
        record.description = "Use case created from quiz scope."
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

    def current_or_submitted_question(quiz:, question:)
      current = quiz.current_question.to_s.strip
      return current unless current.empty?

      question.to_s.strip
    end

    def current_or_submitted_tags(quiz:, tags:)
      return quiz.current_tags if quiz.current_question? || tags.nil?

      Array(tags).map(&:to_s).map(&:strip).reject(&:blank?)
    end

    def next_question_result(quiz, entry: nil)
      quiz.cleanup_stale_candidates!

      if quiz.entries.count >= configuration.max_questions
        quiz.clear_current_question! if quiz.current_question?
        return terminal_result(status: "done", quiz: quiz)
      end

      generated = routed_question_result(quiz, question_provider.generate(input: input_for(quiz, force_deep: deep_fallback_required?(quiz, entry))))
      store_generated_question!(quiz, generated)
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

    def store_generated_question!(quiz, generated)
      return store_fast_candidate!(quiz, generated) if generated.generation_strategy == QuestionProvider::FAST_STRATEGY

      quiz.store_current_question!(
        question: generated.question,
        tags: generated.tags,
        prompt_intent: generated.prompt_intent,
        fallback_reason: generated.fallback_reason,
        errors: generated.errors
      )
    end

    def store_fast_candidate!(quiz, generated)
      candidate = quiz.add_candidate!(
        question: generated.question,
        tags: generated.tags,
        prompt_intent: generated.prompt_intent,
        fallback_reason: generated.fallback_reason,
        errors: generated.errors,
        parent_id: fast_candidate_parent_id(quiz),
        branch_key: "single-candidate"
      )
      quiz.activate_candidate!(candidate.fetch("id"))
    end

    def routed_question_result(quiz, generated)
      generated = trunk_return_result if follow_up_exhausted?(quiz, generated)
      routing_state = routing_state_for(quiz, generated)

      QuestionProvider::Result.new(
        usable: generated.usable?,
        question: generated.question,
        tags: generated.tags,
        follow_up_depth: generated.follow_up_depth,
        completion_recommended: generated.completion_recommended,
        prompt_intent: PromptIntentBuilder.question(
          question: generated.question,
          tags: generated.tags,
          follow_up_depth: generated.follow_up_depth,
          completion_recommended: generated.completion_recommended,
          routing_state: routing_state
        ),
        fallback_reason: generated.fallback_reason,
        errors: generated.errors,
        generation_strategy: generated.generation_strategy
      )
    end

    def trunk_return_result
      QuestionProvider::Result.new(
        usable: false,
        question: TRUNK_RETURN_QUESTION,
        tags: QuestionProvider::FALLBACK_TAGS,
        follow_up_depth: 1,
        completion_recommended: false,
        prompt_intent: {},
        fallback_reason: "follow_up_depth_exhausted",
        errors: ["follow-up depth reached; returning to trunk coverage"],
        generation_strategy: QuestionProvider::DEEP_STRATEGY
      )
    end

    def deep_fallback_required?(quiz, entry)
      quiz.fast_mode? && entry&.answered?
    end

    def fast_candidate_parent_id(quiz)
      "quiz-#{quiz.id}-entry-#{quiz.entries.count}"
    end

    def follow_up_exhausted?(quiz, generated)
      previous_depth = quiz.current_prompt_intent.dig("metadata", "follow_up_depth").to_i
      previous_depth >= configuration.max_follow_up_depth && generated.follow_up_depth.to_i > 1
    end

    def routing_state_for(quiz, generated)
      entry_count = quiz.entries.count
      {
        "phase" => generated.follow_up_depth.to_i > 1 ? "follow_up" : "trunk",
        "entry_count" => entry_count,
        "remaining_questions" => [configuration.max_questions - entry_count, 0].max,
        "follow_up_depth" => generated.follow_up_depth,
        "max_follow_up_depth" => configuration.max_follow_up_depth,
        "trunk_return_recommended" => generated.follow_up_depth.to_i >= configuration.max_follow_up_depth,
        "covered_tags" => covered_tags_for(quiz)
      }
    end

    def covered_tags_for(quiz)
      quiz.entries.includes(:tags).flat_map { |entry| entry.tags.map(&:name) }.uniq.sort
    end

    def current_question_result(quiz)
      Result.new(
        ok: true,
        status: "collecting",
        quiz: quiz,
        entry: nil,
        question: quiz.current_question,
        tags: quiz.current_tags,
        prompt_intent: quiz.current_prompt_intent,
        fallback_reason: quiz.current_fallback_reason,
        errors: quiz.current_question_errors
      )
    end

    def stop_result(status:, quiz:)
      quiz.clear_current_question! if quiz.current_question?
      terminal_result(status: status, quiz: quiz)
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

    def input_for(quiz, force_deep: false)
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
          "entry_count" => quiz.entries.count,
          "mode" => force_deep ? "deep" : quiz.mode
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
      normalized = answer.to_s.strip.downcase.delete_prefix("/")
      CONTROLS.include?(normalized) ? normalized : nil
    end
  end
end
