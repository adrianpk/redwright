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

      queued = queued_fast_candidate_result(quiz)
      return result_from_generated(quiz: quiz, entry: entry, generated: queued) if queued

      input = input_for(quiz)
      generated = routed_question_result(quiz, question_provider.generate(input: input))
      generated = routed_question_result(quiz, question_provider.generate(input: input_for(quiz, force_deep: true))) if repeated_fast_question?(quiz, generated)
      store_generated_question!(quiz, generated)
      result_from_generated(quiz: quiz, entry: entry, generated: generated)
    end

    def result_from_generated(quiz:, entry:, generated:)
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
      candidates = candidates_for(generated).each_with_index.map do |candidate_attributes, index|
        prompt_intent = prompt_intent_for_candidate(candidate_attributes)
        quiz.candidate_payload(
          question: candidate_attributes.fetch("question"),
          tags: candidate_attributes.fetch("tags"),
          prompt_intent: prompt_intent,
          fallback_reason: generated.fallback_reason,
          errors: generated.errors,
          branch_key: "batch-#{quiz.entries.count}-#{index + 1}"
        )
      end
      quiz.update!(candidate_questions: quiz.candidate_questions + candidates)
      candidate = next_active_candidate(quiz.reload)
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
        generation_strategy: generation_strategy_for(generated),
        candidates: generated.candidates
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

    def queued_fast_candidate_result(quiz)
      return nil unless quiz.fast_mode?

      candidate = next_active_candidate(quiz)
      return nil unless candidate

      quiz.activate_candidate!(candidate.fetch("id"))
      routed_question_result(quiz.reload, result_from_candidate(candidate))
    end

    def repeated_fast_question?(quiz, generated)
      generated.generation_strategy == QuestionProvider::FAST_STRATEGY &&
        quiz.current_question.to_s.strip.casecmp?(generated.question.to_s.strip)
    end

    def fast_candidate_parent_id(quiz)
      "quiz-#{quiz.id}-entry-#{quiz.entries.count}"
    end

    def next_active_candidate(quiz)
      quiz.candidate_questions.find { |candidate| candidate.fetch("status") == "active" }
    end

    def candidates_for(generated)
      Array(generated.candidates.presence || [{
        "question" => generated.question,
        "tags" => generated.tags,
        "follow_up_depth" => generated.follow_up_depth,
        "completion_recommended" => generated.completion_recommended
      }])
    end

    def prompt_intent_for_candidate(candidate)
      PromptIntentBuilder.question(
        question: candidate.fetch("question"),
        tags: candidate.fetch("tags"),
        follow_up_depth: candidate.fetch("follow_up_depth"),
        completion_recommended: candidate.fetch("completion_recommended")
      )
    end

    def result_from_candidate(candidate)
      metadata = candidate.fetch("prompt_intent", {}).fetch("metadata", {})
      QuestionProvider::Result.new(
        usable: true,
        question: candidate.fetch("question"),
        tags: candidate.fetch("tags"),
        follow_up_depth: metadata.fetch("follow_up_depth", 1),
        completion_recommended: metadata.fetch("completion_recommended", false),
        prompt_intent: candidate.fetch("prompt_intent"),
        fallback_reason: candidate.fetch("fallback_reason", ""),
        errors: candidate.fetch("errors", []),
        generation_strategy: QuestionProvider::FAST_STRATEGY,
        candidates: [candidate]
      )
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
        "covered_tags" => covered_tags_for(quiz),
        "mode" => quiz.mode,
        "generation_strategy" => generation_strategy_for(generated),
        "fallback_reason" => generated.fallback_reason,
        "candidate_count" => quiz.candidate_questions.count
      }
    end

    def covered_tags_for(quiz)
      quiz.entries.includes(:tags).flat_map { |entry| entry.tags.map(&:name) }.uniq.sort
    end

    def generation_strategy_for(generated)
      generated.generation_strategy.presence || QuestionProvider::DEEP_STRATEGY
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
        "current_question" => {
          "question" => quiz.current_question,
          "tags" => quiz.current_tags,
          "prompt_intent" => quiz.current_prompt_intent
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
