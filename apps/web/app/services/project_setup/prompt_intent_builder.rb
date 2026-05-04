module ProjectSetup
  class PromptIntentBuilder
    class << self
      def setup_slot(slot_key)
        {
          "kind" => "setup_slot_question",
          "slot" => slot_key.to_s,
          "locale" => "auto",
          "llm_required" => true
        }
      end

      def guided_alignment(question_key:, question_text:, question_index:, question_count:)
        {
          "kind" => "guided_alignment_question",
          "question_key" => question_key.to_s,
          "locale" => "auto",
          "llm_required" => false,
          "metadata" => {
            "question_text" => question_text.to_s,
            "question_index" => question_index,
            "question_count" => question_count
          }
        }
      end

      def repository_clarification(question_text:)
        {
          "kind" => "repository_clarification_question",
          "locale" => "auto",
          "llm_required" => false,
          "expected_input_shape" => "repository_reference",
          "metadata" => {
            "question_text" => question_text.to_s
          }
        }
      end

      def prompt_text(intent, fallback: nil)
        normalized = intent.is_a?(Hash) ? intent.transform_keys(&:to_s) : {}
        text = normalized.dig("metadata", "question_text").to_s.strip
        return text unless text.empty?

        if normalized["kind"].to_s == "setup_slot_question"
          return slot_question_text(normalized["slot"])
        end

        fallback.to_s
      end

      private

      def slot_question_text(slot_key)
        case slot_key.to_s
        when "project_name"
          "What should I call this project?"
        when "description"
          "What should this project do?"
        when "project_type"
          "What type of project should this be: CLI, API, web app, library, worker, or something else?"
        when "language_runtime"
          "What primary language or runtime should this project use?"
        when "stack"
          "What stack should I assume for this project?"
        when "framework"
          "What framework should this project use, if any?"
        when "libraries"
          "What main libraries or services should I include or expect?"
        when "repository"
          "Do you want to attach a repository URL or owner/repo now?"
        else
          "What else should I know before creating this project?"
        end
      end
    end
  end
end
