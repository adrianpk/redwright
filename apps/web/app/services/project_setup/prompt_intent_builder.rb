module ProjectSetup
  class PromptIntentBuilder
    class << self
      def setup_slot(slot_key)
        slot = slot_key.to_s
        {
          "kind" => "setup_slot_question",
          "slot" => slot,
          "locale" => "auto",
          "llm_required" => true,
          "metadata" => {
            "semantic_contract" => slot_semantic_contract(slot)
          }
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

      def slot_semantic_contract(slot_key)
        {
          "slot" => slot_key.to_s,
          "intent" => slot_intent(slot_key),
          "expected_answer_kind" => slot_expected_answer_kind(slot_key),
          "question_guidance" => slot_question_guidance(slot_key),
          "forbidden_slots" => forbidden_slots_for(slot_key)
        }
      end

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

      def slot_intent(slot_key)
        case slot_key.to_s
        when "project_name"
          "Ask for the name to use for the project."
        when "description"
          "Ask what the project should do."
        when "project_type"
          "Ask what kind of software project should be created."
        when "language_runtime"
          "Ask which primary programming language or runtime the project should use."
        when "stack"
          "Ask which overall technology stack should be assumed."
        when "framework"
          "Ask which framework should be used, if any."
        when "libraries"
          "Ask which main libraries, services, or integrations should be included or expected."
        when "repository"
          "Ask whether a repository URL or owner/repo reference should be attached."
        else
          "Ask for the next missing project setup detail."
        end
      end

      def slot_expected_answer_kind(slot_key)
        case slot_key.to_s
        when "project_name"
          "project name"
        when "description"
          "short project purpose or behavior description"
        when "project_type"
          "software project archetype, such as CLI, API, web app, library, worker, or another archetype"
        when "language_runtime"
          "programming language or runtime"
        when "stack"
          "technology stack"
        when "framework"
          "framework name or no-framework preference"
        when "libraries"
          "libraries, services, or integrations"
        when "repository"
          "repository URL, SSH URL, or owner/repo reference"
        else
          "project setup detail"
        end
      end

      def slot_question_guidance(slot_key)
        case slot_key.to_s
        when "project_type"
          "Offer broad archetype examples, but do not ask for language, framework, repository, or implementation details."
        when "language_runtime"
          "Ask for the primary language or runtime only; do not ask for framework or project archetype."
        when "framework"
          "Ask for framework preference only; make it clear that no framework is an acceptable answer."
        when "libraries"
          "Ask for notable libraries, services, or integrations only."
        else
          "Ask exactly one concise question for this slot."
        end
      end

      def forbidden_slots_for(slot_key)
        ProjectSetupSession::SETUP_SLOT_KEYS.map(&:to_s) - [slot_key.to_s]
      end
    end
  end
end
