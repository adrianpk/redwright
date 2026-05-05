module QuizLoops
  class CommandQueryHandlers
    def self.register(dispatcher)
      new.register(dispatcher)
    end

    def register(dispatcher)
      dispatcher.register_command("OpenQuiz", method(:open_quiz))
      dispatcher.register_command("AdvanceQuiz", method(:advance_quiz))
      dispatcher.register_query("ListQuizzes", method(:list_quizzes))
    end

    private

    def open_quiz(envelope)
      project = Project.find(envelope.payload.fetch("project_id"))
      runtime = Runtime.new(project: project, use_case_name: envelope.payload["use_case_name"])
      result = runtime.open

      CommandQuery::Result.ok(request_id: envelope.request_id, data: data_from(result))
    rescue ActiveRecord::RecordNotFound => e
      CommandQuery::Result.error(request_id: envelope.request_id, code: "quiz_project_not_found", message: e.message)
    end

    def advance_quiz(envelope)
      project = Project.find(envelope.payload.fetch("project_id"))
      runtime = Runtime.new(project: project, use_case_name: envelope.payload["use_case_name"])
      result = runtime.advance!(
        question: envelope.payload.fetch("question"),
        answer: envelope.payload.fetch("answer"),
        tags: envelope.payload.fetch("tags", [])
      )

      CommandQuery::Result.ok(request_id: envelope.request_id, data: data_from(result))
    rescue ActiveRecord::RecordNotFound => e
      CommandQuery::Result.error(request_id: envelope.request_id, code: "quiz_project_not_found", message: e.message)
    rescue KeyError => e
      CommandQuery::Result.error(request_id: envelope.request_id, code: "quiz_invalid_payload", message: e.message)
    end

    def list_quizzes(envelope)
      project = Project.find(envelope.payload.fetch("project_id"))
      quizzes = project.quizzes.includes(:use_case).order(:use_case_id, :id).map do |quiz|
        {
          "id" => quiz.id,
          "name" => quiz.name,
          "status" => quiz.status,
          "use_case_id" => quiz.use_case_id,
          "use_case_name" => quiz.use_case&.name,
          "entry_count" => quiz.entries.count
        }
      end

      CommandQuery::Result.ok(request_id: envelope.request_id, data: {"project_id" => project.id, "quizzes" => quizzes})
    rescue ActiveRecord::RecordNotFound => e
      CommandQuery::Result.error(request_id: envelope.request_id, code: "quiz_project_not_found", message: e.message)
    end

    def data_from(result)
      {
        "status" => result.status,
        "quiz" => quiz_data(result.quiz),
        "entry" => entry_data(result.entry),
        "question" => result.question,
        "tags" => result.tags,
        "prompt_intent" => result.prompt_intent,
        "fallback_reason" => result.fallback_reason,
        "errors" => result.errors,
        "summary" => summary_for(result)
      }
    end

    def quiz_data(quiz)
      {
        "id" => quiz.id,
        "project_id" => quiz.project_id,
        "use_case_id" => quiz.use_case_id,
        "use_case_name" => quiz.use_case&.name,
        "name" => quiz.name,
        "entry_count" => quiz.entries.count
      }
    end

    def entry_data(entry)
      return nil unless entry

      {
        "id" => entry.id,
        "question" => entry.question,
        "answer" => entry.answer,
        "status" => entry.status,
        "tags" => entry.tags.map(&:name)
      }
    end

    def summary_for(result)
      case result.status
      when "collecting"
        "Quiz question ready."
      when "done"
        "Quiz stopped as done."
      when "cancelled"
        "Quiz cancelled."
      else
        "Quiz updated."
      end
    end
  end
end
